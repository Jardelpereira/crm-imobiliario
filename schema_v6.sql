-- Etapa 6: portfólio de imóveis, perfil do corretor e site público (vitrine.html).
-- Rode uma vez no SQL Editor do Supabase. Pode rodar de novo sem problema.

-- Perfil do corretor: aparece no site público.
create table if not exists perfil (
  user_id uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  nome text, creci text, whatsapp text, cidade text, bio text, foto text,
  atualizado_em timestamptz not null default now()
);
alter table perfil enable row level security;
drop policy if exists "perfil_publico" on perfil;
drop policy if exists "perfil_insert" on perfil;
drop policy if exists "perfil_update" on perfil;
create policy "perfil_publico" on perfil for select using (true);
create policy "perfil_insert" on perfil for insert with check (auth.uid() = user_id);
create policy "perfil_update" on perfil for update using (auth.uid() = user_id);

-- Imóveis: os marcados como publicados aparecem para qualquer pessoa no site.
create table if not exists imoveis (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  titulo text not null,
  tipo text,
  finalidade text not null default 'venda',
  preco numeric,
  bairro text,
  cidade text,
  quartos int,
  banheiros int,
  vagas int,
  area numeric,
  descricao text,
  mcmv boolean not null default false,
  status text not null default 'disponivel' check (status in ('disponivel','reservado','vendido')),
  publicado boolean not null default true,
  destaque boolean not null default false,
  fotos text[] not null default '{}',
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);
create index if not exists imoveis_user_idx on imoveis(user_id, publicado);
alter table imoveis enable row level security;
drop policy if exists "imoveis_select" on imoveis;
drop policy if exists "imoveis_insert" on imoveis;
drop policy if exists "imoveis_update" on imoveis;
drop policy if exists "imoveis_delete" on imoveis;
create policy "imoveis_select" on imoveis for select using (publicado or auth.uid() = user_id);
create policy "imoveis_insert" on imoveis for insert with check (auth.uid() = user_id);
create policy "imoveis_update" on imoveis for update using (auth.uid() = user_id);
create policy "imoveis_delete" on imoveis for delete using (auth.uid() = user_id);

-- Fotos dos imóveis e do corretor: bucket PÚBLICO (qualquer um vê, só o dono envia/apaga).
-- As fichas e documentos dos clientes continuam no bucket privado "fichas".
insert into storage.buckets (id, name, public) values ('imoveis', 'imoveis', true)
on conflict (id) do update set public = true;
drop policy if exists "imoveis_fotos_select" on storage.objects;
drop policy if exists "imoveis_fotos_insert" on storage.objects;
drop policy if exists "imoveis_fotos_delete" on storage.objects;
create policy "imoveis_fotos_select" on storage.objects for select
  using (bucket_id = 'imoveis' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "imoveis_fotos_insert" on storage.objects for insert
  with check (bucket_id = 'imoveis' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "imoveis_fotos_delete" on storage.objects for delete
  using (bucket_id = 'imoveis' and (storage.foldername(name))[1] = auth.uid()::text);
