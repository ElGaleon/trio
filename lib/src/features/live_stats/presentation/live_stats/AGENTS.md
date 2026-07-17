# Pagina statistiche live

Route: `/matches/:matchId/live`. Console operativa per registrare la partita mentre si gioca.

## Flusso

- Carica partita e giocatori tramite provider condivisi usando `matchId`.
- `LiveStatsService` registra goal, errori, blocchi, pull, pause, lineup, sostituzioni e chiusura.
- Bottom sheet e handler raccolgono i dettagli; il servizio applica la mutazione.
- Il riepilogo finale deriva dagli eventi registrati.

## Invarianti

- Un tap non deve registrare due volte lo stesso evento.
- Conferma le azioni distruttive o irreversibili; conserva undo per l'ultima azione supportata.
- Ferma timer e risorse in `dispose`.
- Gestisci partita mancante o già conclusa senza forzare operazioni live.
- Aggiungendo un evento, aggiorna insieme descrizione, riepilogo, timeline e persistenza.
