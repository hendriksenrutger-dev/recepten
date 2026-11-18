-- =====================================================================
--  Beveiliging Supabase voor Cucina + Boodschappen
--
--  Probleem: de huidige regels laten IEDERE ingelogde gebruiker alles doen.
--  Kan iemand zelf een account aanmaken (aanmelden staat standaard aan),
--  dan kan diegene met de openbare sleutel uit de app je recepten en
--  boodschappenlijst lezen, wijzigen en verwijderen.
--
--  Oplossing in twee delen:
--   A. In het dashboard: Authentication -> Sign In / Providers ->
--      "Allow new users to sign up" UIT. (Bestaande accounts blijven werken.)
--   B. Dit script: alleen gebruikers op een vaste lijst krijgen toegang.
--      Het voegt een EXTRA eis toe (restrictive policy). Bestaande regels
--      blijven staan, dus niets wordt ruimer dan het nu is.
--
--  Uitvoeren: Supabase -> SQL Editor. Doe het per stap, in volgorde.
-- =====================================================================


-- STAP 0 - Even kijken (verandert niets) --------------------------------
-- Welke accounts bestaan er? Herken je ze allemaal?
select id, email, created_at, last_sign_in_at from auth.users order by created_at;

-- Welke regels gelden nu?
select tablename, policyname, permissive, roles, cmd, qual
from pg_policies where schemaname in ('public', 'storage') order by tablename;


-- STAP 1 - Lijst met wie erin mag ----------------------------------------
create table if not exists public.toegestane_gebruikers (
  user_id uuid primary key references auth.users(id) on delete cascade
);
-- RLS aan zonder regels: de lijst is niet te lezen of te wijzigen via de app/API.
alter table public.toegestane_gebruikers enable row level security;

-- >>> VUL HIER JE EIGEN E-MAILADRESSEN IN (die uit stap 0) <<<
insert into public.toegestane_gebruikers (user_id)
select id from auth.users
where lower(email) in ('jouw-email@voorbeeld.nl', 'tweede-email@voorbeeld.nl')
on conflict do nothing;

-- Controle: hier moeten precies jullie accounts staan, anders NIET doorgaan.
select u.email from public.toegestane_gebruikers t join auth.users u on u.id = t.user_id;

create or replace function public.is_toegestaan()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.toegestane_gebruikers where user_id = auth.uid());
$$;
revoke all on function public.is_toegestaan() from public;
grant execute on function public.is_toegestaan() to anon, authenticated;


-- STAP 2 - De extra eis op alle tabellen --------------------------------
do $$
declare t text;
begin
  if not exists (select 1 from public.toegestane_gebruikers) then
    raise exception 'De lijst toegestane_gebruikers is leeg: eerst stap 1 goed uitvoeren (anders sluit je jezelf buiten).';
  end if;
  foreach t in array array[
    'recipes',
    'boodschappen_items', 'boodschappen_categorieen', 'boodschappen_product_categorie',
    'boodschappen_vaste_items', 'boodschappen_instellingen', 'boodschappen_barcodes'
  ] loop
    if to_regclass('public.' || t) is null then
      raise notice 'Tabel % bestaat niet, overgeslagen', t;
      continue;
    end if;
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists alleen_huishouden on public.%I', t);
    execute format('create policy alleen_huishouden on public.%I as restrictive for all to public
                    using (public.is_toegestaan()) with check (public.is_toegestaan())', t);
  end loop;
end $$;


-- STAP 3 - Foto's (bucket recipe-photos) ----------------------------------
-- Bekijken blijft openbaar (de app gebruikt openbare links), maar uploaden,
-- vervangen en verwijderen mag alleen nog door gebruikers op de lijst.
drop policy if exists recipe_photos_insert_huishouden on storage.objects;
drop policy if exists recipe_photos_update_huishouden on storage.objects;
drop policy if exists recipe_photos_delete_huishouden on storage.objects;
create policy recipe_photos_insert_huishouden on storage.objects as restrictive for insert to public
  with check (bucket_id <> 'recipe-photos' or public.is_toegestaan());
create policy recipe_photos_update_huishouden on storage.objects as restrictive for update to public
  using (bucket_id <> 'recipe-photos' or public.is_toegestaan());
create policy recipe_photos_delete_huishouden on storage.objects as restrictive for delete to public
  using (bucket_id <> 'recipe-photos' or public.is_toegestaan());


-- STAP 4 - Testen ----------------------------------------------------------
-- Open beide apps op je telefoon: recepten en boodschappenlijst moeten er
-- gewoon staan, en een wijziging opslaan moet werken.
-- Iemand later toevoegen: alleen het insert-blok uit stap 1 opnieuw uitvoeren.


-- ONGEDAAN MAKEN (alleen als er iets misgaat) -----------------------------
-- do $$ declare t text; begin
--   foreach t in array array['recipes','boodschappen_items','boodschappen_categorieen',
--     'boodschappen_product_categorie','boodschappen_vaste_items','boodschappen_instellingen','boodschappen_barcodes'] loop
--     if to_regclass('public.' || t) is not null then
--       execute format('drop policy if exists alleen_huishouden on public.%I', t);
--     end if;
--   end loop; end $$;
-- drop policy if exists recipe_photos_insert_huishouden on storage.objects;
-- drop policy if exists recipe_photos_update_huishouden on storage.objects;
-- drop policy if exists recipe_photos_delete_huishouden on storage.objects;
