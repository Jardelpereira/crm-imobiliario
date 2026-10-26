create table if not exists gastos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  data date not null default current_date,
  categoria text not null default 'outros',
  descricao text,
  valor numeric not null default 0 check (valor >= 0),
  criado_em timestamptz not null default now()
);
create index if not exists gastos_user_idx on gastos(user_id, data);
alter table gastos enable row level security;
drop policy if exists "gastos_select" on gastos;
drop policy if exists "gastos_insert" on gastos;
drop policy if exists "gastos_update" on gastos;
drop policy if exists "gastos_delete" on gastos;
create policy "gastos_select" on gastos for select using (auth.uid() = user_id);
create policy "gastos_insert" on gastos for insert with check (auth.uid() = user_id);
create policy "gastos_update" on gastos for update using (auth.uid() = user_id);
create policy "gastos_delete" on gastos for delete using (auth.uid() = user_id);
notify pgrst, 'reload schema';
