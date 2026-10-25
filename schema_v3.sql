-- Etapa 3: histórico de contatos por cliente. Rode uma vez no SQL Editor do Supabase.
create table if not exists interacoes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  cliente_id uuid not null references clientes(id) on delete cascade,
  tipo text not null default 'Anotação',
  texto text not null,
  criado_em timestamptz not null default now()
);
create index if not exists interacoes_cliente_idx on interacoes(cliente_id, criado_em desc);

alter table interacoes enable row level security;
create policy "interacoes_select" on interacoes for select using (auth.uid() = user_id);
create policy "interacoes_insert" on interacoes for insert with check (auth.uid() = user_id);
create policy "interacoes_update" on interacoes for update using (auth.uid() = user_id);
create policy "interacoes_delete" on interacoes for delete using (auth.uid() = user_id);
