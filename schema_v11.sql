-- Etapa 11: equipe. Corretores da mesma equipe veem e editam os mesmos clientes, agenda,
-- documentos, propostas, vendas e portfólio. Cada um continua com o próprio login.
-- Rode uma vez no SQL Editor do Supabase (depois do schema_v10.sql). Pode rodar de novo sem problema.

create table if not exists equipes (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  codigo text not null unique,
  criado_por uuid default auth.uid() references auth.users(id) on delete set null,
  criado_em timestamptz not null default now()
);
create table if not exists membros (
  user_id uuid primary key references auth.users(id) on delete cascade,
  equipe_id uuid not null references equipes(id) on delete cascade,
  entrou_em timestamptz not null default now()
);
alter table equipes enable row level security;
alter table membros enable row level security;

-- Verdadeiro quando "dono" é o próprio usuário ou alguém da mesma equipe.
create or replace function public.mesma_equipe(dono uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select dono = auth.uid() or exists (
    select 1 from membros a join membros b on b.equipe_id = a.equipe_id
    where a.user_id = auth.uid() and b.user_id = dono);
$$;
-- O mesmo para arquivos: a primeira pasta do caminho é o id de quem enviou.
create or replace function public.mesma_equipe_pasta(caminho text) returns boolean
language sql stable security definer set search_path = public as $$
  select (storage.foldername(caminho))[1] = auth.uid()::text or exists (
    select 1 from membros a join membros b on b.equipe_id = a.equipe_id
    where a.user_id = auth.uid() and b.user_id::text = (storage.foldername(caminho))[1]);
$$;
-- Ids da equipe de um corretor (usado pelo site público para mostrar o portfólio da equipe).
create or replace function public.equipe_de(u uuid) returns setof uuid
language sql stable security definer set search_path = public as $$
  select u union select b.user_id from membros a join membros b on b.equipe_id = a.equipe_id where a.user_id = u;
$$;
grant execute on function public.equipe_de(uuid) to anon, authenticated;

-- Criar equipe, entrar com o código e sair.
create or replace function public.criar_equipe(nome text) returns text
language plpgsql security definer set search_path = public as $$
declare cod text; eq uuid;
begin
  if auth.uid() is null then raise exception 'Faça login primeiro'; end if;
  if exists (select 1 from membros where user_id = auth.uid()) then raise exception 'Você já faz parte de uma equipe'; end if;
  cod := upper(substr(md5(random()::text || clock_timestamp()::text || gen_random_uuid()::text), 1, 12));
  insert into equipes (nome, codigo, criado_por) values (coalesce(nullif(trim(nome), ''), 'Minha equipe'), cod, auth.uid()) returning id into eq;
  insert into membros (user_id, equipe_id) values (auth.uid(), eq);
  return cod;
end $$;
create or replace function public.entrar_equipe(cod text) returns text
language plpgsql security definer set search_path = public as $$
declare eq uuid; n text;
begin
  if auth.uid() is null then raise exception 'Faça login primeiro'; end if;
  select id, nome into eq, n from equipes where codigo = upper(trim(cod));
  if eq is null then raise exception 'Código de equipe não encontrado'; end if;
  if exists (select 1 from membros where user_id = auth.uid()) then raise exception 'Você já faz parte de uma equipe. Saia dela antes.'; end if;
  insert into membros (user_id, equipe_id) values (auth.uid(), eq);
  return n;
end $$;
create or replace function public.sair_equipe() returns void
language sql security definer set search_path = public as $$
  delete from membros where user_id = auth.uid();
$$;

drop policy if exists "equipes_select" on equipes;
create policy "equipes_select" on equipes for select using (exists (select 1 from membros where membros.user_id = auth.uid() and membros.equipe_id = equipes.id));
drop policy if exists "membros_select" on membros;
create policy "membros_select" on membros for select using (mesma_equipe(user_id));

-- Tabelas do CRM: ver, editar e excluir o que é seu ou da sua equipe. Inserir continua sendo em seu nome.
do $$
declare t text;
begin
  foreach t in array array['clientes','interacoes','documentos','compromissos','vendas','propostas'] loop
    execute format('drop policy if exists %I on %I', t || '_select', t);
    execute format('drop policy if exists %I on %I', t || '_update', t);
    execute format('drop policy if exists %I on %I', t || '_delete', t);
    execute format('create policy %I on %I for select using (mesma_equipe(user_id))', t || '_select', t);
    execute format('create policy %I on %I for update using (mesma_equipe(user_id))', t || '_update', t);
    execute format('create policy %I on %I for delete using (mesma_equipe(user_id))', t || '_delete', t);
  end loop;
end $$;

drop policy if exists "imoveis_select" on imoveis;
drop policy if exists "imoveis_update" on imoveis;
drop policy if exists "imoveis_delete" on imoveis;
create policy "imoveis_select" on imoveis for select using (publicado or mesma_equipe(user_id));
create policy "imoveis_update" on imoveis for update using (mesma_equipe(user_id));
create policy "imoveis_delete" on imoveis for delete using (mesma_equipe(user_id));

-- Arquivos (fichas e documentos no bucket privado "fichas"; fotos no bucket público "imoveis").
drop policy if exists "fichas_select" on storage.objects;
drop policy if exists "fichas_insert" on storage.objects;
drop policy if exists "fichas_delete" on storage.objects;
create policy "fichas_select" on storage.objects for select using (bucket_id = 'fichas' and public.mesma_equipe_pasta(name));
create policy "fichas_insert" on storage.objects for insert with check (bucket_id = 'fichas' and public.mesma_equipe_pasta(name));
create policy "fichas_delete" on storage.objects for delete using (bucket_id = 'fichas' and public.mesma_equipe_pasta(name));
drop policy if exists "imoveis_fotos_select" on storage.objects;
drop policy if exists "imoveis_fotos_insert" on storage.objects;
drop policy if exists "imoveis_fotos_delete" on storage.objects;
create policy "imoveis_fotos_select" on storage.objects for select using (bucket_id = 'imoveis' and public.mesma_equipe_pasta(name));
create policy "imoveis_fotos_insert" on storage.objects for insert with check (bucket_id = 'imoveis' and public.mesma_equipe_pasta(name));
create policy "imoveis_fotos_delete" on storage.objects for delete using (bucket_id = 'imoveis' and public.mesma_equipe_pasta(name));
