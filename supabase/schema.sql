-- Zerava Filmboard: initial PostgreSQL schema for Supabase
create extension if not exists pgcrypto;
create type public.member_role as enum ('owner','admin','moderator','member');
create type public.project_status as enum ('idea','pre_production','production','post_production','completed','on_hold');
create table public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null default 'Anggota Zerava', job_title text, avatar_url text, bio text,
 is_online boolean not null default false, last_seen_at timestamptz, created_at timestamptz not null default now()
);
create table public.servers (
 id uuid primary key default gen_random_uuid(), name text not null, description text, image_url text,
 owner_id uuid not null references public.profiles(id) on delete cascade, created_at timestamptz not null default now()
);
create table public.server_members (
 server_id uuid references public.servers(id) on delete cascade, user_id uuid references public.profiles(id) on delete cascade,
 role public.member_role not null default 'member', joined_at timestamptz not null default now(), primary key(server_id,user_id)
);
create table public.channels (
 id uuid primary key default gen_random_uuid(), server_id uuid not null references public.servers(id) on delete cascade,
 name text not null, channel_type text not null default 'text' check(channel_type in ('text','announcement','media')), position int not null default 0
);
create table public.posts (
 id uuid primary key default gen_random_uuid(), author_id uuid not null references public.profiles(id) on delete cascade,
 body text not null, media_url text, media_type text, tag text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.post_likes (post_id uuid references public.posts(id) on delete cascade, user_id uuid references public.profiles(id) on delete cascade, created_at timestamptz default now(), primary key(post_id,user_id));
create table public.post_comments (id uuid primary key default gen_random_uuid(), post_id uuid not null references public.posts(id) on delete cascade, author_id uuid not null references public.profiles(id) on delete cascade, body text not null, created_at timestamptz default now());
create table public.projects (
 id uuid primary key default gen_random_uuid(), title text not null, synopsis text, project_type text, status public.project_status not null default 'idea',
 owner_id uuid not null references public.profiles(id) on delete cascade, server_id uuid references public.servers(id) on delete set null,
 start_date date, target_date date, budget numeric(14,2) default 0, created_at timestamptz default now()
);
create table public.project_members (project_id uuid references public.projects(id) on delete cascade, user_id uuid references public.profiles(id) on delete cascade, crew_role text, primary key(project_id,user_id));
create table public.production_tasks (id uuid primary key default gen_random_uuid(), project_id uuid not null references public.projects(id) on delete cascade, title text not null, details text, due_at timestamptz, assigned_to uuid references public.profiles(id) on delete set null, status text not null default 'todo', created_at timestamptz default now());
create table public.project_assets (id uuid primary key default gen_random_uuid(), project_id uuid not null references public.projects(id) on delete cascade, uploaded_by uuid references public.profiles(id) on delete set null, file_url text not null, file_name text, asset_type text, created_at timestamptz default now());
create table public.screenplay_scenes (id uuid primary key default gen_random_uuid(), project_id uuid not null references public.projects(id) on delete cascade, scene_number int not null, heading text, content text default '', updated_at timestamptz default now());
create table public.shot_lists (id uuid primary key default gen_random_uuid(), project_id uuid not null references public.projects(id) on delete cascade, scene_id uuid references public.screenplay_scenes(id) on delete set null, shot_number int, shot_description text, camera_angle text, lens text, status text default 'planned');
create table public.budget_items (id uuid primary key default gen_random_uuid(), project_id uuid not null references public.projects(id) on delete cascade, category text, description text, planned_amount numeric(14,2) default 0, actual_amount numeric(14,2) default 0, created_at timestamptz default now());
create table public.academy_posts (id uuid primary key default gen_random_uuid(), author_id uuid not null references public.profiles(id) on delete cascade, title text not null, body text not null, category text, cover_url text, video_url text, created_at timestamptz default now());
create table public.bookmarks (user_id uuid references public.profiles(id) on delete cascade, academy_post_id uuid references public.academy_posts(id) on delete cascade, created_at timestamptz default now(), primary key(user_id,academy_post_id));
create table public.conversations (id uuid primary key default gen_random_uuid(), is_group boolean default false, title text, created_at timestamptz default now());
create table public.conversation_members (conversation_id uuid references public.conversations(id) on delete cascade, user_id uuid references public.profiles(id) on delete cascade, primary key(conversation_id,user_id));
create table public.messages (id uuid primary key default gen_random_uuid(), conversation_id uuid not null references public.conversations(id) on delete cascade, sender_id uuid not null references public.profiles(id) on delete cascade, body text, attachment_url text, created_at timestamptz default now());
create table public.notifications (id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade, title text not null, body text, target_url text, read_at timestamptz, created_at timestamptz default now());

-- Profile creation from Supabase Auth
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin insert into public.profiles(id,display_name) values(new.id,coalesce(new.raw_user_meta_data->>'name',split_part(new.email,'@',1))); return new; end; $$;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

-- Enable RLS on all user-facing tables
alter table public.profiles enable row level security; alter table public.servers enable row level security; alter table public.server_members enable row level security; alter table public.channels enable row level security;
alter table public.posts enable row level security; alter table public.post_likes enable row level security; alter table public.post_comments enable row level security; alter table public.projects enable row level security;
alter table public.project_members enable row level security; alter table public.production_tasks enable row level security; alter table public.project_assets enable row level security; alter table public.screenplay_scenes enable row level security;
alter table public.shot_lists enable row level security; alter table public.budget_items enable row level security; alter table public.academy_posts enable row level security; alter table public.bookmarks enable row level security;
alter table public.conversations enable row level security; alter table public.conversation_members enable row level security; alter table public.messages enable row level security; alter table public.notifications enable row level security;
-- Public member directory, self-editable profile
create policy "profiles readable by authenticated" on public.profiles for select to authenticated using(true);
create policy "profile owner updates own" on public.profiles for update to authenticated using(auth.uid()=id) with check(auth.uid()=id);
-- Public community feed, author-only write/delete
create policy "posts readable by authenticated" on public.posts for select to authenticated using(true);
create policy "authors create posts" on public.posts for insert to authenticated with check(auth.uid()=author_id);
create policy "authors update posts" on public.posts for update to authenticated using(auth.uid()=author_id) with check(auth.uid()=author_id);
create policy "authors delete posts" on public.posts for delete to authenticated using(auth.uid()=author_id);
create policy "likes readable" on public.post_likes for select to authenticated using(true);
create policy "users manage own likes" on public.post_likes for all to authenticated using(auth.uid()=user_id) with check(auth.uid()=user_id);
create policy "comments readable" on public.post_comments for select to authenticated using(true);
create policy "users create comments" on public.post_comments for insert to authenticated with check(auth.uid()=author_id);
-- Academy: all signed-in members can share and read
create policy "academy readable" on public.academy_posts for select to authenticated using(true);
create policy "members publish academy" on public.academy_posts for insert to authenticated with check(auth.uid()=author_id);
create policy "authors edit academy" on public.academy_posts for update to authenticated using(auth.uid()=author_id) with check(auth.uid()=author_id);
create policy "authors delete academy" on public.academy_posts for delete to authenticated using(auth.uid()=author_id);
create policy "own bookmarks" on public.bookmarks for all to authenticated using(auth.uid()=user_id) with check(auth.uid()=user_id);
-- Servers and project visibility; projects are public to signed-in members as requested
create policy "servers readable" on public.servers for select to authenticated using(true);
create policy "members create servers" on public.servers for insert to authenticated with check(auth.uid()=owner_id);
create policy "server owner updates" on public.servers for update to authenticated using(auth.uid()=owner_id) with check(auth.uid()=owner_id);
create policy "projects readable" on public.projects for select to authenticated using(true);
create policy "members create projects" on public.projects for insert to authenticated with check(auth.uid()=owner_id);
create policy "project owner updates" on public.projects for update to authenticated using(auth.uid()=owner_id) with check(auth.uid()=owner_id);
-- Private messaging: only conversation members can read/write
create policy "conversation membership visible to self" on public.conversation_members for select to authenticated using(auth.uid()=user_id);
create policy "members read conversations" on public.conversations for select to authenticated using(exists(select 1 from public.conversation_members cm where cm.conversation_id=id and cm.user_id=auth.uid()));
create policy "members read messages" on public.messages for select to authenticated using(exists(select 1 from public.conversation_members cm where cm.conversation_id=conversation_id and cm.user_id=auth.uid()));
create policy "members send messages" on public.messages for insert to authenticated with check(auth.uid()=sender_id and exists(select 1 from public.conversation_members cm where cm.conversation_id=conversation_id and cm.user_id=auth.uid()));
create policy "users read own notifications" on public.notifications for select to authenticated using(auth.uid()=user_id);
create policy "users update own notifications" on public.notifications for update to authenticated using(auth.uid()=user_id) with check(auth.uid()=user_id);
-- Storage buckets: create `avatars`, `community-media`, `project-assets` in Supabase Storage UI.
-- Add authenticated read policies and owner-folder write policies before enabling uploads.
