-- Etapa 7: agenda de visitas, retornos e outros compromissos.
-- Rode uma vez no SQL Editor do Supabase (depois do schema_v6.sql). Pode rodar de novo sem problema.
create table if not exists compromissos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  cliente_id uuid references clientes(id) on delete cascade,
  imovel_id uuid references imoveis(id) on delete set null,
  tipo text not null default 'visita' check (tipo in ('visita','retorno','assinatura','reuniao','outro')),
  quando timestamptz not null,
  duracao int not null default 60,
  local text,
  obs text,
  feito boolean not null default false,
  resultado text,
  criado_em timestamptz not null default now()
);
create index if not exists compromissos_user_idx on compromissos(user_id, quando);

alter table compromissos enable row level security;
drop policy if exists "compromissos_select" on compromissos;
drop policy if exists "compromissos_insert" on compromissos;
drop policy if exists "compromissos_update" on compromissos;
drop policy if exists "compromissos_delete" on compromissos;
create policy "compromissos_select" on compromissos for select using (auth.uid() = user_id);
create policy "compromissos_insert" on compromissos for insert with check (auth.uid() = user_id);
create policy "compromissos_update" on compromissos for update using (auth.uid() = user_id);
create policy "compromissos_delete" on compromissos for delete using (auth.uid() = user_id);
