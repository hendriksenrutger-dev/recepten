# Mijn Recepten App

Persoonlijke PWA receptenverzameling. Donker thema, oranje accenten, installeerbaar op telefoon.

## GitHub Pages Deployment

1. Maak een nieuw GitHub repository aan (bijv. `mijn-recepten`)
2. Upload alle bestanden (inclusief `icons/` map)
3. Ga naar **Settings → Pages**
4. Kies **Source: Deploy from a branch → main → / (root)**
5. Na ~1 minuut is de app live op `https://jouwgebruikersnaam.github.io/mijn-recepten/`

## Icons maken

Maak twee vierkante PNG iconen en zet ze in een `icons/` map:
- `icons/icon-192.png` (192×192 px)
- `icons/icon-512.png` (512×512 px)

Gebruik bijv. een 🍳 emoji op een oranje achtergrond (#FF6B35).

## URL Import

Voor het importeren van webrecepten heb je een Anthropic API key nodig:
1. Ga naar https://console.anthropic.com
2. Maak een API key aan
3. Klik op ⚙️ in de app en vul je key in

De key wordt lokaal opgeslagen in je browser (localStorage), nooit gedeeld.

## Offline gebruik

De app werkt offline na de eerste bezoek (Service Worker cacht alle bestanden).
Recepten worden opgeslagen in localStorage van de browser.
