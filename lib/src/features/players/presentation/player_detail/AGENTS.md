# Pagina dettaglio giocatore

Route: `/players/:playerId`. Mostra profilo, rating, statistiche filtrabili e partite del giocatore.

## Dati

- `playerDetailStatsProvider(playerId)` combina giocatore e partite.
- I filtri torneo e partita sono family provider legati all'ID.
- Le righe partita navigano al dettaglio della partita.
- Modifica e azioni sul profilo usano sempre l'ID corrente.

## Modifiche

- Gestisci giocatore inesistente e giocatore senza partite.
- Non ricalcolare statistiche dentro i widget.
- Mantieni filtri coerenti: una partita selezionata deve appartenere al torneo disponibile.
- Riusa hero, box statistici, pill e righe locali.
