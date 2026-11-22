// App instalável: registra o service worker e mostra o botão "Instalar app".
(function () {
  if ("serviceWorker" in navigator) {
    window.addEventListener("load", () => navigator.serviceWorker.register("sw.js").catch(() => {}));
  }
  const instalado = window.matchMedia("(display-mode: standalone)").matches || navigator.standalone === true;
  const btn = document.getElementById("instalar");
  if (!btn || instalado) return;

  let pedido = null;
  // Android / Chrome / Edge: o navegador avisa que dá para instalar.
  window.addEventListener("beforeinstallprompt", (e) => {
    e.preventDefault();
    pedido = e;
    btn.classList.remove("hide");
  });
  window.addEventListener("appinstalled", () => { btn.classList.add("hide"); pedido = null; });

  // iPhone / iPad (Safari) não tem esse aviso: mostramos a dica.
  const ios = /iphone|ipad|ipod/i.test(navigator.userAgent) || (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1);
  if (ios) btn.classList.remove("hide");

  btn.addEventListener("click", async () => {
    if (pedido) {
      pedido.prompt();
      await pedido.userChoice.catch(() => {});
      pedido = null;
      btn.classList.add("hide");
    } else {
      const dica = document.getElementById("dicaios");
      if (dica) dica.classList.toggle("hide");
    }
  });
  const fechar = document.getElementById("dicaiosok");
  if (fechar) fechar.addEventListener("click", () => document.getElementById("dicaios").classList.add("hide"));
})();
