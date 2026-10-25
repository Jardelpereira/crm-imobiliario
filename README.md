# CRM Imobiliário

CRM em HTML puro para corretor de imóveis, com login e banco no Supabase.

## Arquivos
- `index.html` — CRM (login, cadastro de clientes, filtro por status, botão WhatsApp)
- `importar.html` — importação de clientes a partir de planilha CSV
- `config.js` — URL e chave publishable do Supabase (pública por desenho; a proteção vem do login + RLS)
- `schema.sql` — tabela `clientes`, políticas RLS e bucket `fichas`
- `schema_v2.sql` — colunas da etapa 2 (nascimento, renda, filhos)

## Como usar
1. No Supabase, rode `schema.sql` e depois `schema_v2.sql` no SQL Editor.
2. Abra `index.html` (ou sirva a pasta com `python -m http.server 8765` e acesse http://localhost:8765).
3. Crie a conta, confirme o e-mail e entre.

Planilhas com dados de clientes (`*.csv`) ficam fora do repositório pelo `.gitignore`.

## Importar fichas por foto

O botão "Importar fichas" na página principal envia a foto para a função `ler-ficha` do Supabase
(`supabase/functions/ler-ficha/index.ts`), que lê a letra com a API da Anthropic e devolve os clientes
para conferência antes de salvar.

Configuração única no Supabase:
1. Edge Functions > Deploy a new function > "Via Editor", nome `ler-ficha`, colar o conteúdo do arquivo acima.
2. Edge Functions > Secrets > adicionar `ANTHROPIC_API_KEY` com a chave criada em console.anthropic.com.
