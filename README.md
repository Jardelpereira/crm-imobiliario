# CRM Imobiliário

CRM em HTML puro para corretor de imóveis, com login e banco no Supabase.

## Arquivos
- `index.html` — CRM (login, cadastro de clientes, filtro por status, botão WhatsApp)
- `importar.html` — importação de clientes a partir de planilha CSV
- `vitrine.html` — site público com o portfólio de imóveis (link `vitrine.html?c=<id do corretor>`)
- `config.js` — URL e chave publishable do Supabase (pública por desenho; a proteção vem do login + RLS)
- `schema.sql` — tabela `clientes`, políticas RLS e bucket `fichas`
- `schema_v2.sql` a `schema_v10.sql` — etapas seguintes (campos das fichas, histórico, esteira, documentos, portfólio, perfil, agenda e vendas)

## Como usar
1. No Supabase, rode no SQL Editor, em ordem: `schema.sql`, `schema_v2.sql`, `schema_v3.sql`, `schema_v5.sql`, `schema_v6.sql`, `schema_v7.sql`, `schema_v8.sql`, `schema_v9.sql` e `schema_v10.sql`.
2. Abra `index.html` (ou sirva a pasta com `python -m http.server 8765` e acesse http://localhost:8765).
3. Crie a conta, confirme o e-mail e entre.

Planilhas com dados de clientes (`*.csv`) ficam fora do repositório pelo `.gitignore`.
