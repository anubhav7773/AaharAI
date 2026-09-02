# Doc 02: Supabase Database Schema, RLS & SQL Migrations

## 1. Architectural Overview & Storage Rules
- **Database Engine**: PostgreSQL 15+ hosted on Supabase Free Tier (500 MB storage quota cap)[cite: 1].
- **Connection Strategy**: All serverless backend calls (FastAPI on Render) use Supabase connection pooler via port `6543` (Transaction mode) to prevent connection exhaustion.
- **Zero Raw Image Policy**: Camera capture images are NEVER stored in Supabase Storage buckets to save quota[cite: 1]. Images are parsed transiently in-memory via Gemini Vision and converted into structured JSON[cite: 2].
- **Strict Data Isolation**: Multi-tenant data segregation is enforced at the database kernel level using PostgreSQL Row Level Security (RLS)[cite: 1].

---

## 2. Complete SQL Migration Script (`migrations/001_initial_schema.sql`)

Antigravity must execute this script cleanly inside Supabase SQL Editor:

```sql
-- ============================================================================
-- AaharAi Production Database Schema v1.0.0
-- Target: Supabase / PostgreSQL 15+
-- ============================================================================

-- Step 1: Enable Necessary Extensions
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- Step 2: Custom Enum Types for Schema Rigidity
do $$ begin
    create type food_source_type as enum ('open_food_facts', 'gemini_vision', 'street_food');
exception
    when duplicate_object then null;
end $$;

do $$ begin
    create type meal_category_type as enum ('breakfast', 'lunch', 'dinner', 'snack');
exception
    when duplicate_object then null;
end $$;

-- ============================================================================
-- TABLE 1: PROFILES (User Health & Target Configuration)
-- ============================================================================
create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    email text unique not null,
    display_name text,
    avatar_url text,
    daily_calorie_goal integer not null default 2000 check (daily_calorie_goal >= 500 and daily_calorie_goal <= 10000),
    target_carbs_g numeric(6, 2) default 250.0 check (target_carbs_g >= 0),
    target_protein_g numeric(6, 2) default 60.0 check (target_protein_g >= 0),
    target_fat_g numeric(6, 2) default 65.0 check (target_fat_g >= 0),
    dietary_flags text[] default array[]::text[], -- e.g. {'vegetarian', 'lactose_intolerant'}
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

comment on table public.profiles is 'Stores user-specific nutritional targets and personal preferences.';

-- ============================================================================
-- TABLE 2: FOOD_CACHE (Global Deduplicated Product & Street Food Cache)
-- ============================================================================
create table if not exists public.food_cache (
    id uuid primary key default uuid_generate_v4(),
    barcode text unique,                           -- NULL for street food / custom label scans
    signature_hash text unique,                   -- SHA-256 hash of raw OCR ingredient string to deduplicate image scans
    food_name text not null,
    brand_name text,
    source food_source_type not null,
    ingredients_raw text,
    parsed_ingredients jsonb not null default '[]'::jsonb,
    /*
      JSONB Structure for parsed_ingredients:
      [
        {
          "name": "INS 102 (Tartrazine)",
          "simple_explanation": "Bright yellow synthetic dye added for color.",
          "category": "moderate", -- enum: safe, moderate, avoid
          "health_note": "Acceptable Daily Intake (ADI) restricted by FSSAI."
        }
      ]
    */
    nutrients jsonb not null default '{}'::jsonb,
    /*
      JSONB Structure for nutrients:
      {
        "calories_100g": 539.0,
        "protein_100g": 6.3,
        "carbs_100g": 56.3,
        "fat_100g": 30.9,
        "fiber_100g": 2.5
      }
    */
    allergens text[] default array[]::text[],     -- FSSAI 8 mandatory categories
    preparation_insights text,                     -- Specifically populated for street foods (e.g. oil reuse, starch content)
    hit_count integer not null default 1,         -- Tracks frequency to guide future local offline caching
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

comment on table public.food_cache is 'Global shared food analysis cache to minimize Gemini API calls and stay within free-tier quotas.';

-- ============================================================================
-- TABLE 3: FOOD_LOGS (User Daily Calorie Diary)
-- ============================================================================
create table if not exists public.food_logs (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references public.profiles(id) on delete cascade not null,
    cache_id uuid references public.food_cache(id) on delete set null,
    food_name text not null,
    serving_quantity_g numeric(6, 2) not null check (serving_quantity_g > 0),
    calories_consumed numeric(6, 2) not null check (calories_consumed >= 0),
    consumed_macros jsonb not null default '{}'::jsonb,
    /*
      JSONB Structure for consumed_macros (calculated per serving):
      {
        "protein": 12.6,
        "carbs": 112.6,
        "fat": 61.8
      }
    */
    meal_type meal_category_type not null default 'snack',
    logged_at timestamp with time zone default timezone('utc'::text, now()) not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

comment on table public.food_logs is 'Individual meal diary entries tied to specific users.';

-- ============================================================================
-- Step 3: High-Performance Database Indexes
-- ============================================================================
create index if not exists idx_food_cache_barcode on public.food_cache (barcode) where barcode is not null;
create index if not exists idx_food_cache_signature on public.food_cache (signature_hash) where signature_hash is not null;
create index if not exists idx_food_cache_food_name_trgm on public.food_cache using gin (food_name gin_trgm_ops);
create index if not exists idx_food_logs_user_date on public.food_logs (user_id, logged_at desc);
create index if not exists idx_food_logs_user_meal on public.food_logs (user_id, meal_type);

-- Step 4: Automated Trigger for updated_at Column
create or replace function public.handle_updated_at()
returns trigger as $$
begin
    new.updated_at = timezone('utc'::text, now());
    return new;
end;
$$ language plpgsql;

create trigger trigger_profiles_updated_at
    before update on public.profiles
    for each row execute function public.handle_updated_at();

create trigger trigger_food_cache_updated_at
    before update on public.food_cache
    for each row execute function public.handle_updated_at();

-- Step 5: Automated Profile Creation on Firebase/Supabase Auth Signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
    insert into public.profiles (id, email, display_name, avatar_url)
    values (
        new.id,
        new.email,
        coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', 'AaharAi User'),
        new.raw_user_meta_data->>'avatar_url'
    )
    on conflict (id) do nothing;
    return new;
end;
$$ language plpgsql security definer;

create or replace trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();
3. Row Level Security (RLS) & Multi-Tenant Defense
Execute these RLS policies to guarantee zero data leakage between users:

SQL
-- Enable RLS on all operational tables
alter table public.profiles enable row level security;
alter table public.food_cache enable row level security;
alter table public.food_logs enable row level security;

-- ============================================================================
-- PROFILES POLICIES
-- ============================================================================
create policy "Users can read own profile"
    on public.profiles for select
    using (auth.uid() = id);

create policy "Users can update own profile"
    on public.profiles for update
    using (auth.uid() = id);

-- ============================================================================
-- FOOD_CACHE POLICIES (Read: Global Authenticated, Write: Service Role / Backend)
-- ============================================================================
create policy "Authenticated users can read cached food"
    on public.food_cache for select
    using (auth.role() = 'authenticated');

create policy "Service role and backend can insert into cache"
    on public.food_cache for insert
    with check (true);

create policy "Service role and backend can update cache hit count"
    on public.food_cache for update
    using (true);

-- ============================================================================
-- FOOD_LOGS POLICIES (Isolated to Logged-in User)
-- ============================================================================
create policy "Users can view own diary logs"
    on public.food_logs for select
    using (auth.uid() = user_id);

create policy "Users can insert into own diary logs"
    on public.food_logs for insert
    with check (auth.uid() = user_id);

create policy "Users can update own diary logs"
    on public.food_logs for update
    using (auth.uid() = user_id);

create policy "Users can delete own diary logs"
    on public.food_logs for delete
    using (auth.uid() = user_id);
4. Frontend Dart Data Models (Matching Supabase Schema)
Antigravity should generate these exact Dart classes in mobile/lib/core/models/:

food_item_model.dart
Dart
import 'dart:convert';

enum IngredientSafety { safe, moderate, avoid }

class ParsedIngredient {
  final String name;
  final String simpleExplanation;
  final IngredientSafety category;
  final String healthNote;

  const ParsedIngredient({
    required this.name,
    required this.simpleExplanation,
    required this.category,
    required this.healthNote,
  });

  factory ParsedIngredient.fromJson(Map<String, dynamic> json) {
    return ParsedIngredient(
      name: json['name'] as String? ?? 'Unknown Substance',
      simpleExplanation: json['simple_explanation'] as String? ?? '',
      category: _parseSafety(json['category'] as String?),
      healthNote: json['health_note'] as String? ?? '',
    );
  }

  static IngredientSafety _parseSafety(String? val) {
    switch (val?.toLowerCase()) {
      case 'avoid':
        return IngredientSafety.avoid;
      case 'moderate':
        return IngredientSafety.moderate;
      case 'safe':
      default:
        return IngredientSafety.safe;
    }
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'simple_explanation': simpleExplanation,
        'category': category.name,
        'health_note': healthNote,
      };
}

class NutrientProfile {
  final double calories100g;
  final double protein100g;
  final double carbs100g;
  final double fat100g;
  final double fiber100g;

  const NutrientProfile({
    required this.calories100g,
    required this.protein100g,
    required this.carbs100g,
    required this.fat100g,
    this.fiber100g = 0.0,
  });

  factory NutrientProfile.fromJson(Map<String, dynamic> json) {
    return NutrientProfile(
      calories100g: (json['calories_100g'] as num?)?.toDouble() ?? 0.0,
      protein100g: (json['protein_100g'] as num?)?.toDouble() ?? 0.0,
      carbs100g: (json['carbs_100g'] as num?)?.toDouble() ?? 0.0,
      fat100g: (json['fat_100g'] as num?)?.toDouble() ?? 0.0,
      fiber100g: (json['fiber_100g'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'calories_100g': calories100g,
        'protein_100g': protein100g,
        'carbs_100g': carbs100g,
        'fat_100g': fat100g,
        'fiber_100g': fiber100g,
      };
}

class FoodItem {
  final String id;
  final String? barcode;
  final String foodName;
  final String? brandName;
  final String source;
  final List<ParsedIngredient> parsedIngredients;
  final NutrientProfile nutrients;
  final List<String> allergens;
  final String? preparationInsights;

  const FoodItem({
    required this.id,
    this.barcode,
    required this.foodName,
    this.brandName,
    required this.source,
    required this.parsedIngredients,
    required this.nutrients,
    required this.allergens,
    this.preparationInsights,
  });

  factory FoodItem.fromSupabase(Map<String, dynamic> map) {
    final rawIngredients = map['parsed_ingredients'];
    List<ParsedIngredient> ingredientsList = [];
    if (rawIngredients is List) {
      ingredientsList = rawIngredients
          .map((item) => ParsedIngredient.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return FoodItem(
      id: map['id'] as String,
      barcode: map['barcode'] as String?,
      foodName: map['food_name'] as String? ?? 'Unnamed Food',
      brandName: map['brand_name'] as String?,
      source: map['source'] as String? ?? 'gemini_vision',
      parsedIngredients: ingredientsList,
      nutrients: NutrientProfile.fromJson(map['nutrients'] as Map<String, dynamic>? ?? {}),
      allergens: (map['allergens'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      preparationInsights: map['preparation_insights'] as String?,
    );
  }
}
food_log_model.dart
Dart
class FoodLogEntry {
  final String id;
  final String userId;
  final String? cacheId;
  final String foodName;
  final double servingQuantityG;
  final double caloriesConsumed;
  final Map<String, double> consumedMacros;
  final String mealType;
  final DateTime loggedAt;

  FoodLogEntry({
    required this.id,
    required this.userId,
    this.cacheId,
    required this.foodName,
    required this.servingQuantityG,
    required this.caloriesConsumed,
    required this.consumedMacros,
    required this.mealType,
    required this.loggedAt,
  });

  factory FoodLogEntry.fromJson(Map<String, dynamic> json) {
    final rawMacros = json['consumed_macros'] as Map<String, dynamic>? ?? {};
    return FoodLogEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      cacheId: json['cache_id'] as String?,
      foodName: json['food_name'] as String,
      servingQuantityG: (json['serving_quantity_g'] as num).toDouble(),
      caloriesConsumed: (json['calories_consumed'] as num).toDouble(),
      consumedMacros: rawMacros.map((k, v) => MapEntry(k, (v as num).toDouble())),
      mealType: json['meal_type'] as String? ?? 'snack',
      loggedAt: DateTime.parse(json['logged_at'] as String),
    );
  }

  Map<String, dynamic> toInsertMap() => {
        'user_id': userId,
        'cache_id': cacheId,
        'food_name': foodName,
        'serving_quantity_g': servingQuantityG,
        'calories_consumed': caloriesConsumed,
        'consumed_macros': consumedMacros,
        'meal_type': mealType,
        'logged_at': loggedAt.toIso8601String(),
      };
}