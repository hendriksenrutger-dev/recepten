// Cucina service worker (zelfde aanpak als de boodschappen-app)
// - De app zelf (index.html): altijd eerst het netwerk, zodat je de nieuwste versie krijgt.
//   Geen antwoord binnen 3 seconden (slecht bereik)? Dan de bewaarde versie.
// - Overige bestanden (iconen, manifest, lettertypen): uit de cache, op de achtergrond ververst.
// - Recepten (Supabase) en AI-aanvragen gaan nooit via de cache.
// - Ruimt alleen eigen caches op (voorvoegsel 'cucina-'), nooit die van Boodschappen.
// Je hoeft dit bestand NIET aan te passen bij een nieuwe versie van index.html.

const PREFIX = 'cucina-';
const CACHE = PREFIX + 'v60';
const APP = new URL('index.html', self.registration.scope).href;
const VOORAF = ['index.html', 'manifest.json', 'icon-192.png', 'icon-512.png'];
const EXTERN = ['fonts.googleapis.com', 'fonts.gstatic.com'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(VOORAF)).catch(() => {}));
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil((async () => {
    const namen = await caches.keys();
    await Promise.all(namen.filter(n => n.startsWith(PREFIX) && n !== CACHE).map(n => caches.delete(n)));
    await self.clients.claim();
  })());
});

function metTijdslimiet(promise, ms) {
  return new Promise((resolve, reject) => {
    const t = setTimeout(() => reject(new Error('timeout')), ms);
    promise.then(r => { clearTimeout(t); resolve(r); }, err => { clearTimeout(t); reject(err); });
  });
}

self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return;                              // opslaan, AI, inloggen: nooit cachen
  const url = new URL(req.url);
  if (url.hostname.endsWith('supabase.co')) return;               // recepten en foto's: altijd vers

  const binnenApp = url.origin === self.location.origin && url.href.startsWith(self.registration.scope);
  const isPagina = binnenApp && (req.mode === 'navigate' || url.pathname.endsWith('/') || url.pathname.endsWith('/index.html'));

  // manifest.json altijd vers van het netwerk (anders ziet Chrome een oud manifest)
  if (binnenApp && url.pathname.endsWith('/manifest.json')) {
    e.respondWith(fetch(req, { cache: 'no-store' }).catch(() => caches.match(req)));
    return;
  }

  if (isPagina) {
    e.respondWith((async () => {
      const cache = await caches.open(CACHE);
      const netwerk = fetch(APP, { cache: 'no-store' }).then(res => {
        if (res.ok) cache.put(APP, res.clone());
        return res;
      });
      try {
        return await metTijdslimiet(netwerk, 3000);
      } catch {
        const bewaard = await cache.match(APP);
        if (bewaard) return bewaard;
        return netwerk;                                            // nog niets bewaard: gewoon wachten
      }
    })());
    return;
  }

  if (binnenApp || EXTERN.includes(url.hostname)) {
    e.respondWith((async () => {
      const cache = await caches.open(CACHE);
      const bewaard = await cache.match(req);
      const vers = fetch(req).then(res => {
        if (res && (res.ok || res.type === 'opaque')) cache.put(req, res.clone());
        return res;
      }).catch(() => bewaard);
      return bewaard || vers;
    })());
  }
});
