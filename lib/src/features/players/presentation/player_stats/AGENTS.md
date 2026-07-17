# Pagina statistiche giocatori

Route: `/stats`. Confronta rendimento, presenze e metriche aggregate dei giocatori.

## Stato

- `playerAnalyticsProvider` costruisce l'analisi da giocatori filtrati e partite.
- Ricerca, ruolo e linea usano i provider `stats*FilterProvider`.
- `selectedStatsPlayerIdProvider` controlla l'eventuale selezione di dettaglio.

## Modifiche

- Aggiungi metriche al modello analitico prima di renderizzarle.
- Evita divisioni per zero e distingui assenza di dati da valore zero.
- Applica i filtri prima dell'aggregazione.
- Mantieni confronti e ordinamenti deterministici a parità di valore.
