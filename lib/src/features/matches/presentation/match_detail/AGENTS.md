# Pagina dettaglio partita

Route: `/matches/:matchId`. Presenta risultato, andamento Elo, timeline e statistiche individuali o aggregate.

## Stato e dati

- La partita arriva dall'archivio tramite ID; gestisci sempre il caso non trovato.
- `matchDetailTabProvider(matchId)` seleziona la sezione principale.
- `matchDetailSubTabProvider(matchId)` seleziona la sottosezione statistica.
- Timeline e riepiloghi derivano da `ScrimmageMatch.statEvents`.
- Modifica e live stats sono rotte figlie della partita corrente.

## Modifiche

- Calcola dati aggregati nei modelli/provider, non durante il rendering delle righe.
- Mantieni coerenti punteggio, timeline e statistiche quando introduci un tipo evento.
- Riusa i componenti locali per titoli, team, hero e grafici.
- Un evento assente deve produrre uno stato vuoto, non un errore.
