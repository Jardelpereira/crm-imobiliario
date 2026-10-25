-- Etapa 5: novas etapas da esteira e documentos dos clientes. Rode uma vez no SQL Editor do Supabase.
-- Pode rodar mesmo que o schema_v4.sql já tenha sido rodado, e pode rodar de novo sem problema.
alter table clientes drop constraint if exists clientes_status_check;
alter table clientes add constraint clientes_status_check check (status in (
  'lead','visita','visita_feita','proposta','documentacao','negociacao','vistoria','aprovado','subsidio','contrato','fechado','perdido'
));

-- Checklist de documentos por cliente (os arquivos ficam no bucket privado "fichas").
create table if not exists documentos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  cliente_id uuid not null references clientes(id) on delete cascade,
  tipo text not null,
  entregue boolean not null default false,
  arquivo text,
  nome_arquivo text,
  atualizado_em timestamptz not null default now(),
  unique (cliente_id, tipo)
);

alter table documentos enable row level security;
drop policy if exists "documentos_select" on documentos;
drop policy if exists "documentos_insert" on documentos;
drop policy if exists "documentos_update" on documentos;
drop policy if exists "documentos_delete" on documentos;
create policy "documentos_select" on documentos for select using (auth.uid() = user_id);
create policy "documentos_insert" on documentos for insert with check (auth.uid() = user_id);
create policy "documentos_update" on documentos for update using (auth.uid() = user_id);
create policy "documentos_delete" on documentos for delete using (auth.uid() = user_id);
