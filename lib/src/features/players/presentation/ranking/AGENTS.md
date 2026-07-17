# Pagina ranking

Route iniziale: `/ranking`. Classifica i giocatori per rating Elo e mostra podio, trend e medie per linea.

## Dati

- `rankedPlayersProvider` fornisce l'ordine ufficiale.
- `filteredRankingPlayersProvider` applica filtri per ruolo e linea.
- Le card aprono il dettaglio del giocatore.
- Trend e riepiloghi devono derivare dai dati analitici esistenti.

## Modifiche

- Non riordinare localmente con criteri diversi dal repository.
- Mantieni funzionanti i casi con zero, uno o due giocatori.
- Riusa card, badge, pill e avatar esistenti.
- I grafici custom devono gestire liste vuote e un singolo valore.
