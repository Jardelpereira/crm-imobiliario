-- Etapa 4: esteira de vendas com mais etapas. Rode uma vez no SQL Editor do Supabase.
-- Os clientes atuais continuam válidos (as etapas antigas foram mantidas).
alter table clientes drop constraint if exists clientes_status_check;
alter table clientes add constraint clientes_status_check check (status in (
  'lead','visita','visita_feita','proposta','documentacao','negociacao','aprovado','contrato','fechado','perdido'
));
