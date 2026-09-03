-- ============================================================================
-- AaharAi Migration 002: Fix Profiles Table for Anonymous / Guest Users
-- Target: Supabase / PostgreSQL 15+
-- Safe to re-run idempotently.
-- ============================================================================

-- Step 1: Drop NOT NULL constraint on public.profiles.email to allow guest users
alter table public.profiles
    alter column email drop not null;

-- Step 2: Clean up any existing empty strings to NULL to respect the UNIQUE constraint
update public.profiles
set email = null
where trim(email) = '';

-- Step 3: Update trigger function to insert NULL for users without emails (guests)
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
        nullif(trim(coalesce(new.email, '')), ''),
        coalesce(new.raw_user_meta_data ->> 'full_name', 'Guest User'),
        new.raw_user_meta_data ->> 'avatar_url'
    )
    on conflict (id) do update
    set email = coalesce(excluded.email, public.profiles.email),
        display_name = coalesce(excluded.display_name, public.profiles.display_name),
        avatar_url = coalesce(excluded.avatar_url, public.profiles.avatar_url);
    return new;
end;
$$;
