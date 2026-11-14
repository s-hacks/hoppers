-- Hoppers schema — paste this into the Supabase SQL editor and run once.

create table if not exists classes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  emoji text not null default '🐰',
  color_index int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists messages (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references classes(id) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  role text not null check (role in ('user','assistant')),
  content text not null,
  created_at timestamptz not null default now()
);

create table if not exists materials (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references classes(id) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  file_name text not null,
  type text not null check (type in ('pdf','image','text')),
  storage_path text not null,
  extracted_text text,
  created_at timestamptz not null default now()
);

create index if not exists classes_user_created_idx on classes (user_id, created_at);
create index if not exists messages_class_created_idx on messages (class_id, created_at);
create index if not exists materials_class_created_idx on materials (class_id, created_at);

alter table classes enable row level security;
alter table messages enable row level security;
alter table materials enable row level security;

drop policy if exists "own classes" on classes;
create policy "own classes"
  on classes for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "own messages" on messages;
create policy "own messages"
  on messages for all
  using (
    user_id = auth.uid()
    and class_id in (select id from classes where user_id = auth.uid())
  )
  with check (
    user_id = auth.uid()
    and class_id in (select id from classes where user_id = auth.uid())
  );

drop policy if exists "own materials" on materials;
create policy "own materials"
  on materials for all
  using (
    user_id = auth.uid()
    and class_id in (select id from classes where user_id = auth.uid())
  )
  with check (
    user_id = auth.uid()
    and class_id in (select id from classes where user_id = auth.uid())
  );

grant select, insert, update, delete on classes, messages, materials to authenticated;

insert into storage.buckets (id, name, public)
values ('materials', 'materials', false)
on conflict (id) do nothing;

drop policy if exists "own files" on storage.objects;
create policy "own files"
  on storage.objects for all
  using (
    bucket_id = 'materials'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'materials'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
