// Edge Function do Supabase: lê uma foto de ficha manuscrita e devolve os clientes encontrados.
// Precisa do segredo ANTHROPIC_API_KEY (Project Settings > Edge Functions > Secrets).
// O login do usuário é verificado pelo próprio Supabase (verify_jwt ligado por padrão).

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const resposta = (corpo: unknown, status = 200) =>
  new Response(JSON.stringify(corpo), { status, headers: { ...CORS, "Content-Type": "application/json" } });

const SISTEMA = `Você lê fichas de captação de clientes de um corretor de imóveis (programa Minha Casa Minha Vida), escritas à mão em português do Brasil.
Cada ficha tem: Nome, Tel, CPF, Data de N., Form./Infor. (marcação de renda formal ou informal), Renda B., Possui filhos? Sim/Não, Obs. e anotações soltas nas margens e embaixo.
Regras:
- Leia somente fichas preenchidas. Ignore blocos em branco.
- Nunca invente. Se um campo estiver ilegível ou ausente, deixe vazio e descreva a dúvida em "conferir" (por exemplo "CPF: último dígito incerto").
- telefone: só dígitos com DDD, sem o 55. cpf no formato 000.000.000-00 quando houver 11 dígitos, senão só o que estiver legível e avise em "conferir". data_nascimento em AAAA-MM-DD; anos com dois dígitos: 00 a 26 vira 20xx, o resto 19xx.
- tipo_renda: "formal" se Form. estiver marcado, "informal" se Infor. estiver marcado. renda: número em reais.
- tem_filhos: true, false ou omitido se não estiver marcado.
- status: "perdido" para "não tem interesse", "reprovado" ou "aprovada não quis"; "visita" para visita agendada; caso contrário "lead".
- observacoes: tudo o que estiver escrito como anotação (ex.: "chamei no WhatsApp", "não atendeu", siglas da margem como SJ, OK, CCAP), copiado como está.
- origem: preencha só se a ficha disser (ex.: indicação).
- Se a data da ficha aparecer no topo, ignore-a nos campos, mas pode citá-la em observacoes.`;

const FERRAMENTA = {
  name: "registrar_fichas",
  description: "Registra as fichas preenchidas encontradas na imagem",
  input_schema: {
    type: "object",
    properties: {
      pessoas: {
        type: "array",
        items: {
          type: "object",
          properties: {
            nome: { type: "string" },
            telefone: { type: "string" },
            cpf: { type: "string" },
            data_nascimento: { type: "string" },
            tipo_renda: { type: "string", enum: ["formal", "informal"] },
            renda: { type: "number" },
            tem_filhos: { type: "boolean" },
            status: { type: "string", enum: ["lead", "visita", "proposta", "negociacao", "fechado", "perdido"] },
            origem: { type: "string" },
            observacoes: { type: "string" },
            conferir: { type: "string" },
          },
          required: ["nome"],
        },
      },
    },
    required: ["pessoas"],
  },
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return resposta({ error: "Use POST" }, 405);

  const chave = Deno.env.get("ANTHROPIC_API_KEY");
  if (!chave) return resposta({ error: "Falta o segredo ANTHROPIC_API_KEY no Supabase." }, 500);

  let imagem: string;
  try {
    ({ imagem } = await req.json());
  } catch {
    return resposta({ error: "Corpo inválido." }, 400);
  }
  if (!imagem || typeof imagem !== "string") return resposta({ error: "Envie a imagem em base64." }, 400);
  if (imagem.length > 7_000_000) return resposta({ error: "Imagem grande demais." }, 413);

  const r = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: { "x-api-key": chave, "anthropic-version": "2023-06-01", "content-type": "application/json" },
    body: JSON.stringify({
      model: "claude-sonnet-5-5",
      max_tokens: 4096,
      system: SISTEMA,
      tools: [FERRAMENTA],
      tool_choice: { type: "tool", name: "registrar_fichas" },
      messages: [{
        role: "user",
        content: [
          { type: "image", source: { type: "base64", media_type: "image/jpeg", data: imagem } },
          { type: "text", text: "Leia todas as fichas preenchidas desta página." },
        ],
      }],
    }),
  });

  if (!r.ok) {
    const detalhe = await r.text();
    return resposta({ error: `Falha ao ler a ficha (${r.status}). ${detalhe.slice(0, 300)}` }, 502);
  }
  const dados = await r.json();
  const bloco = (dados.content ?? []).find((b: { type: string }) => b.type === "tool_use");
  return resposta({ pessoas: bloco?.input?.pessoas ?? [] });
});
