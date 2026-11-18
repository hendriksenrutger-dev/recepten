# Cucina Hendriksen

Persoonlijke receptenverzameling als web-app (PWA), installeerbaar op je telefoon.
Live op GitHub Pages: `https://hendriksenrutger-dev.github.io/recepten/`

## Wat kan de app

- **Recepten toevoegen** op veel manieren: handmatig, via een URL, een foto
  (ook handgeschreven), een PDF, of laten bedenken op basis van ingrediënten.
- **Koken:** kookstand met grote stappen, timers en scherm-aan, en
  "samen koken" om meerdere gerechten tegelijk te plannen.
- **Extra's:** porties omrekenen, voedingswaarden, wijnadvies, "lekker met",
  weekmenu, tips per recept, foto's.
- **Boodschappen:** ingrediënten met één tik naar de
  [Boodschappen-app](https://github.com/hendriksenrutger-dev/Boodschappen).
  Beide apps delen dezelfde login.

## Hoe het werkt

| Onderdeel | Waar |
|---|---|
| App | `index.html` (alles in één bestand) |
| Recepten, foto's, login | Supabase (tabel `recipes`, bucket `recipe-photos`) |
| AI-functies | Claude API, met je eigen API-sleutel (⚙️ in de app) |
| Offline | `sw.js` bewaart de app; recepten komen altijd vers uit de database |
| Beveiliging database | `supabase/beveiliging.sql` |

De Anthropic API-sleutel wordt alleen in je eigen browser bewaard (localStorage).
Stel in de [Anthropic Console](https://console.anthropic.com) een uitgavenlimiet in.
De gebruikte Claude-modellen staan bovenaan het script in `index.html`
(`AI_MODEL` en `AI_MODEL_SNEL`).

## Nieuwe versie uitbrengen

1. Pas `index.html` aan en hoog het versienummer op in `<meta name="version">`.
2. Zet het bestand op GitHub (branch `main`). Na ongeveer een minuut staat het live.
3. Op de telefoon: de app één keer sluiten en weer openen.

`sw.js` hoeft daarvoor niet aangepast te worden.
