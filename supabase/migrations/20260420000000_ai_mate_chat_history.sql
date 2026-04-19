-- ai_conversations + ai_messages for AI Mate chat history.
-- Applied via Supabase MCP on 2026-04-20 (project uwjmeitzpxvohmqxfaxy).

create table if not exists public.ai_conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.ai_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.ai_conversations(id) on delete cascade,
  role text not null check (role in ('user','assistant','system')),
  content text not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_ai_conversations_user_updated
  on public.ai_conversations(user_id, updated_at desc);
create index if not exists idx_ai_messages_conv_created
  on public.ai_messages(conversation_id, created_at);

alter table public.ai_conversations enable row level security;
alter table public.ai_messages enable row level security;

drop policy if exists "ai_conversations_select" on public.ai_conversations;
drop policy if exists "ai_conversations_insert" on public.ai_conversations;
drop policy if exists "ai_conversations_update" on public.ai_conversations;
drop policy if exists "ai_conversations_delete" on public.ai_conversations;

create policy "ai_conversations_select" on public.ai_conversations
  for select using (user_id = auth.uid());
create policy "ai_conversations_insert" on public.ai_conversations
  for insert with check (user_id = auth.uid());
create policy "ai_conversations_update" on public.ai_conversations
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "ai_conversations_delete" on public.ai_conversations
  for delete using (user_id = auth.uid());

drop policy if exists "ai_messages_select" on public.ai_messages;
drop policy if exists "ai_messages_insert" on public.ai_messages;
drop policy if exists "ai_messages_update" on public.ai_messages;
drop policy if exists "ai_messages_delete" on public.ai_messages;

create policy "ai_messages_select" on public.ai_messages
  for select using (
    exists (
      select 1 from public.ai_conversations c
      where c.id = ai_messages.conversation_id and c.user_id = auth.uid()
    )
  );
create policy "ai_messages_insert" on public.ai_messages
  for insert with check (
    exists (
      select 1 from public.ai_conversations c
      where c.id = ai_messages.conversation_id and c.user_id = auth.uid()
    )
  );
create policy "ai_messages_update" on public.ai_messages
  for update using (
    exists (
      select 1 from public.ai_conversations c
      where c.id = ai_messages.conversation_id and c.user_id = auth.uid()
    )
  );
create policy "ai_messages_delete" on public.ai_messages
  for delete using (
    exists (
      select 1 from public.ai_conversations c
      where c.id = ai_messages.conversation_id and c.user_id = auth.uid()
    )
  );

create or replace function public.bump_ai_conversation_updated_at()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.ai_conversations
     set updated_at = now()
   where id = new.conversation_id;
  return new;
end;
$$;

drop trigger if exists trg_bump_ai_conversation_updated_at on public.ai_messages;
create trigger trg_bump_ai_conversation_updated_at
  after insert on public.ai_messages
  for each row
  execute function public.bump_ai_conversation_updated_at();
