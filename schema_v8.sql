-- Etapa 8: imóvel de interesse do cliente e controle de vendas/comissões.
-- Rode uma vez no SQL Editor do Supabase (depois do schema_v6.sql). Pode rodar de novo sem problema.

-- Imóvel de interesse e valor no cadastro do cliente.
alter table clientes add column if not exists imovel_id uuid references imoveis(id) on delete set null;
alter table clientes add column if not exists valor_imovel numeric;

-- Meta mensal e comissão padrão no perfil do corretor.
alter table perfil add column if not exists meta_mensal numeric;
alter table perfil add column if not exists comissao_padrao numeric;

-- Vendas concluídas.
create table if not exists vendas (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  cliente_id uuid references clientes(id) on delete set null,
  cliente_nome text,
  imovel_id uuid references imoveis(id) on delete set null,
  imovel_desc text,
  data_venda date not null default current_date,
  valor_venda numeric not null default 0,
  comissao_pct numeric not null default 5,
  divisao_pct numeric not null default 100,
  forma_pagamento text,
  pagamento_status text not null default 'pendente' check (pagamento_status in ('pendente','parcial','recebido')),
  valor_recebido numeric not null default 0,
  data_recebimento date,
  obs text,
  criado_em timestamptz not null default now()
);
create index if not exists vendas_user_idx on vendas(user_id, data_venda);

alter table vendas enable row level security;
drop policy if exists "vendas_select" on vendas;
drop policy if exists "vendas_insert" on vendas;
drop policy if exists "vendas_update" on vendas;
drop policy if exists "vendas_delete" on vendas;
create policy "vendas_select" on vendas for select using (auth.uid() = user_id);
create policy "vendas_insert" on vendas for insert with check (auth.uid() = user_id);
create policy "vendas_update" on vendas for update using (auth.uid() = user_id);
create policy "vendas_delete" on vendas for delete using (auth.uid() = user_id);
