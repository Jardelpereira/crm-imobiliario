-- CRM Imobiliário - etapa 1
-- Cole este arquivo inteiro no SQL Editor do Supabase e clique em Run.

create table if not exists clientes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  nome text not null,
  telefone text,
  email text,
  cpf text,
  status text not null default 'lead'
    check (status in ('lead','visita','proposta','negociacao','fechado','perdido')),
  interesse text,
  orcamento numeric,
  origem text,
  observacoes text,
  ficha_url text,
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);

create index if not exists clientes_user_idx on clientes(user_id, status);

alter table clientes enable row level security;

-- Cada usuário só enxerga e altera os próprios clientes (base pronta para multiusuário).
create policy "clientes_select" on clientes for select using (auth.uid() = user_id);
create policy "clientes_insert" on clientes for insert with check (auth.uid() = user_id);
create policy "clientes_update" on clientes for update using (auth.uid() = user_id);
create policy "clientes_delete" on clientes for delete using (auth.uid() = user_id);

-- Bucket privado para as fotos das fichas manuscritas (etapa 2).
insert into storage.buckets (id, name, public) values ('fichas', 'fichas', false)
on conflict (id) do nothing;

create policy "fichas_select" on storage.objects for select
  using (bucket_id = 'fichas' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "fichas_insert" on storage.objects for insert
  with check (bucket_id = 'fichas' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "fichas_delete" on storage.objects for delete
  using (bucket_id = 'fichas' and (storage.foldername(name))[1] = auth.uid()::text);
