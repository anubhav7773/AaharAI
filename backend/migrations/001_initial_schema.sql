-- AaharAi production schema, PostgreSQL 15+ / Supabase.
-- Safe to re-run after an interrupted migration.

create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";
create extension if not exists "pg_trgm";

do $$
begin
    create type public.food_source_type as enum (
        'open_food_facts',
        'gemini_vision',
        'street_food'
    );
exception
    when duplicate_object then null;
end
$$;

do $$
begin
    create type public.meal_category_type as enum (
        'breakfast',
        'lunch',
        'dinner',
        'snack'
    );
exception
    when duplicate_object then null;
end
$$;

create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    email text unique not null,
    display_name text,
    avatar_url text,
    daily_calorie_goal integer not null default 2000
        check (daily_calorie_goal >= 500 and daily_calorie_goal <= 10000),
    target_carbs_g numeric(6, 2) not null default 250.0
        check (target_carbs_g >= 0),
    target_protein_g numeric(6, 2) not null default 60.0
        check (target_protein_g >= 0),
    target_fat_g numeric(6, 2) not null default 65.0
        check (target_fat_g >= 0),
    dietary_flags text[] not null default array[]::text[],
    created_at timestamptz not null default timezone('utc'::text, now()),
    updated_at timestamptz not null default timezone('utc'::text, now())
);

create table if not exists public.food_cache (
    id uuid primary key default uuid_generate_v4(),
    barcode text unique,
    signature_hash text unique,
    food_name text not null,
    brand_name text,
    source public.food_source_type not null,
    ingredients_raw text,
    parsed_ingredients jsonb not null default '[]'::jsonb,
    nutrients jsonb not null default '{}'::jsonb,
    allergens text[] not null default array[]::text[],
    preparation_insights text,
    hit_count integer not null default 1 check (hit_count >= 1),
    created_at timestamptz not null default timezone('utc'::text, now()),
    updated_at timestamptz not null default timezone('utc'::text, now())
);

create table if not exists public.food_logs (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid not null references public.profiles(id) on delete cascade,
    cache_id uuid references public.food_cache(id) on delete set null,
    food_name text not null,
    serving_quantity_g numeric(6, 2) not null check (serving_quantity_g > 0),
    calories_consumed numeric(6, 2) not null check (calories_consumed >= 0),
    consumed_macros jsonb not null default '{}'::jsonb,
    meal_type public.meal_category_type not null default 'snack',
    logged_at timestamptz not null default timezone('utc'::text, now()),
    created_at timestamptz not null default timezone('utc'::text, now())
);

create index if not exists food_cache_barcode_idx
    on public.food_cache (barcode)
    where barcode is not null;

create index if not exists food_cache_signature_hash_idx
    on public.food_cache (signature_hash)
    where signature_hash is not null;

create index if not exists food_cache_food_name_trgm_idx
    on public.food_cache using gin (food_name gin_trgm_ops);

create index if not exists food_logs_user_logged_at_idx
    on public.food_logs (user_id, logged_at desc);

create index if not exists food_logs_user_meal_type_idx
    on public.food_logs (user_id, meal_type);

create or replace function public.handle_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
    new.updated_at = timezone('utc'::text, now());
    return new;
end;
$$;

drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at
before update on public.profiles
for each row execute function public.handle_updated_at();

drop trigger if exists food_cache_updated_at on public.food_cache;
create trigger food_cache_updated_at
before update on public.food_cache
for each row execute function public.handle_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.profiles (id, email, display_name, avatar_url)
    values (
        new.id,
        coalesce(new.email, ''),
        new.raw_user_meta_data ->> 'full_name',
        new.raw_user_meta_data ->> 'avatar_url'
    )
    on conflict (id) do update
    set email = excluded.email,
        display_name = coalesce(excluded.display_name, public.profiles.display_name),
        avatar_url = coalesce(excluded.avatar_url, public.profiles.avatar_url);
    return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.food_cache enable row level security;
alter table public.food_logs enable row level security;

drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own
on public.profiles for select
to authenticated
using (auth.uid() = id);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own
on public.profiles for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists food_cache_select_authenticated on public.food_cache;
create policy food_cache_select_authenticated
on public.food_cache for select
to authenticated
using (auth.role() = 'authenticated');

drop policy if exists food_logs_select_own on public.food_logs;
create policy food_logs_select_own
on public.food_logs for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists food_logs_insert_own on public.food_logs;
create policy food_logs_insert_own
on public.food_logs for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists food_logs_update_own on public.food_logs;
create policy food_logs_update_own
on public.food_logs for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists food_logs_delete_own on public.food_logs;
create policy food_logs_delete_own
on public.food_logs for delete
to authenticated
using (auth.uid() = user_id);
