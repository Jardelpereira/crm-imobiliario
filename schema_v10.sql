-- Etapa 10: parcela desejada do cliente e propostas/simulações do banco (Caixa).
-- Rode uma vez no SQL Editor do Supabase. Pode rodar de novo sem problema.
alter table clientes add column if not exists parcela_desejada numeric;

create table if not exists propostas (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  cliente_id uuid not null references clientes(id) on delete cascade,
  data date not null default current_date,
  banco text not null default 'Caixa',
  modalidade text,
  valor_imovel numeric,
  entrada numeric,
  fgts numeric,
  subsidio numeric,
  valor_financiado numeric,
  prazo_meses int,
  taxa_juros numeric,
  sistema text,
  parcela numeric,
  renda_considerada numeric,
  status text not null default 'simulada' check (status in ('simulada','em_analise','aprovada','reprovada')),
  obs text,
  criado_em timestamptz not null default now()
);
create index if not exists propostas_cliente_idx on propostas(cliente_id, data desc);

alter table propostas enable row level security;
drop policy if exists "propostas_select" on propostas;
drop policy if exists "propostas_insert" on propostas;
drop policy if exists "propostas_update" on propostas;
drop policy if exists "propostas_delete" on propostas;
create policy "propostas_select" on propostas for select using (auth.uid() = user_id);
create policy "propostas_insert" on propostas for insert with check (auth.uid() = user_id);
create policy "propostas_update" on propostas for update using (auth.uid() = user_id);
create policy "propostas_delete" on propostas for delete using (auth.uid() = user_id);
