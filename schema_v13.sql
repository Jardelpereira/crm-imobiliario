alter table clientes drop constraint if exists clientes_status_check;
alter table clientes add constraint clientes_status_check check (status in ('lead','visita','visita_feita','proposta','documentacao','negociacao','vistoria','aprovado','subsidio','contrato','fechado','reavaliacao','perdido'));
alter table clientes add column if not exists reavaliar_em date;
alter table clientes add column if not exists motivo_reprovacao text;
notify pgrst, 'reload schema';
