# Feature partite

Gestisce elenco, creazione/modifica, dettaglio, statistiche registrate e aggiornamento Elo.

## Strati

- `domain/`: `ScrimmageMatch`, eventi statistici, stato del form e tab del dettaglio.
- `data/`: adapter Hive e `EloRepository`.
- `application/`: provider di elenco/filtri, form e selezione tab.
- `presentation/`: pagine `matches`, `match_form` e `match_detail`.

## Invarianti

- Ogni giocatore può appartenere a una sola squadra nella stessa partita.
- Gli aggiornamenti persistenti passano da `EloRepository`.
- Una modifica a risultato o roster può cambiare il rating: preserva ricalcolo e storico.
- Modificando `ScrimmageMatch`, aggiorna l'adapter senza riutilizzare field index esistenti.
- I provider derivati devono reagire a `hiveChangesProvider`, non mantenere copie dell'archivio.
