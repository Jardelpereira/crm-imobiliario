-- Etapa 4: novas etapas da esteira, documentos do cliente e arquivos.
-- Rode uma vez no SQL Editor do Supabase.

alter table clientes drop constraint if exists clientes_status_check;
alter table clientes add constraint clientes_status_check check (status in (
  'lead','visita','visita_feita','proposta','documentacao','negociacao',
  'aprovado','subsidio','vistoria','contrato','fechado','perdido'));

alter table clientes add column if not exists docs jsonb not null default '{}'::jsonb;

create table if not exists arquivos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  cliente_id uuid not null references clientes(id) on delete cascade,
  tipo text not null,
  nome text not null,
  path text not null,
  tamanho bigint,
  criado_em timestamptz not null default now()
);
create index if not exists arquivos_cliente_idx on arquivos(cliente_id, criado_em);
alter table arquivos enable row level security;
drop policy if exists "arquivos_select" on arquivos;
drop policy if exists "arquivos_insert" on arquivos;
drop policy if exists "arquivos_delete" on arquivos;
create policy "arquivos_select" on arquivos for select using (auth.uid() = user_id);
create policy "arquivos_insert" on arquivos for insert with check (auth.uid() = user_id);
create policy "arquivos_delete" on arquivos for delete using (auth.uid() = user_id);

insert into storage.buckets (id, name, public) values ('documentos', 'documentos', false)
on conflict (id) do nothing;
drop policy if exists "documentos_select" on storage.objects;
drop policy if exists "documentos_insert" on storage.objects;
drop policy if exists "documentos_delete" on storage.objects;
create policy "documentos_select" on storage.objects for select
  using (bucket_id = 'documentos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "documentos_insert" on storage.objects for insert
  with check (bucket_id = 'documentos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "documentos_delete" on storage.objects for delete
  using (bucket_id = 'documentos' and (storage.foldername(name))[1] = auth.uid()::text);
