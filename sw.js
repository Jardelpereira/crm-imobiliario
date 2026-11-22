// Service worker do app instalável.
// Guarda só os arquivos do próprio site (telas, ícones). Nunca guarda nada
// do Supabase nem de outros sites: dados de clientes sempre vêm da internet.
const VERSAO = "crm-v1";
const ARQUIVOS = [
  "./", "./index.html", "./importar.html", "./config.js", "./pwa.js",
  "./manifest.json", "./icones/icone-192.png", "./icones/icone-512.png",
  "./icones/apple-touch-icon.png", "./icones/favicon.png"
];

self.addEventListener("install", (e) => {
  e.waitUntil(caches.open(VERSAO).then((c) => c.addAll(ARQUIVOS)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", (e) => {
  e.waitUntil(
    caches.keys()
      .then((nomes) => Promise.all(nomes.filter((n) => n !== VERSAO).map((n) => caches.delete(n))))
      .then(() => self.clients.claim())
  );
});

// Internet primeiro (sempre a versão mais nova); a cópia guardada só é usada sem sinal.
self.addEventListener("fetch", (e) => {
  const req = e.request;
  const url = new URL(req.url);
  if (req.method !== "GET" || url.origin !== self.location.origin) return;
  const caminho = "." + url.pathname.slice(new URL(self.registration.scope).pathname.length - 1);
  const guardavel = ARQUIVOS.includes(caminho);
  e.respondWith(
    fetch(req)
      .then((resp) => {
        if (guardavel && resp.ok) {
          const copia = resp.clone();
          caches.open(VERSAO).then((c) => c.put(req, copia));
        }
        return resp;
      })
      .catch(() =>
        caches.match(req, { ignoreSearch: true }).then((r) => r || (req.mode === "navigate" ? caches.match("./index.html") : undefined))
          .then((r) => r || Response.error())
      )
  );
});
