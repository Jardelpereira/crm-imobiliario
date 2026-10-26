-- Etapa 9: prazo para o cliente entregar os documentos e aviso (com som) antes dos compromissos.
-- Rode uma vez no SQL Editor do Supabase (depois do schema_v7.sql). Pode rodar de novo sem problema.
alter table clientes add column if not exists prazo_docs date;
alter table compromissos add column if not exists lembrete_min int not null default 30;
