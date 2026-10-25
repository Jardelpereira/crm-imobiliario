-- Etapa 2: campos que aparecem nas fichas de papel. Rode uma vez no SQL Editor do Supabase.
alter table clientes add column if not exists data_nascimento date;
alter table clientes add column if not exists tipo_renda text check (tipo_renda in ('formal','informal'));
alter table clientes add column if not exists renda numeric;
alter table clientes add column if not exists tem_filhos boolean;
