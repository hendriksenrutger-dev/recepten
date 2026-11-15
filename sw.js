const CACHE = 'cucina-v59';
const SCOPE = '/recepten/';
const ASSETS = ['/recepten/','/recepten/index.html','/recepten/manifest.json','/recepten/icon-192.png','/recepten/icon-512.png'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(ASSETS).catch(()=>{})));
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k.startsWith('cucina-') && k !== CACHE).map(k => caches.delete(k)))   // alleen eigen caches, niet die van Boodschappen
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', e => {
  if (!e.request.url.includes(SCOPE)) return;
  e.respondWith(fetch(e.request).catch(() => caches.match(e.request)));
});
