alter table clientes add column if not exists etapa text not null default 'contato';
alter table clientes add column if not exists etapas jsonb not null default '{}'::jsonb;
update clientes set etapa = case status
  when 'visita' then 'visita_agendada'
  when 'proposta' then 'documentos'
  when 'negociacao' then 'financiamento'
  when 'fechado' then 'chaves'
  else 'contato' end
where etapa = 'contato' and status <> 'lead';
