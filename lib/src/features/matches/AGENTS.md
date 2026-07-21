# Feature partite

Gestisce elenco, creazione/modifica, dettaglio, statistiche registrate e aggiornamento Elo.

## Strati

- `domain/`: `ScrimmageMatch`, eventi statistici, stato del form e tab del dettaglio.
- `data/`: persistenza Firestore condivisa in `FirestoreTrioRepository`.
- `application/`: provider di elenco/filtri, form e selezione tab basati su Firestore.
- `presentation/`: pagine `matches`, `match_form` e `match_detail`.

## Invarianti

- Ogni giocatore può appartenere a una sola squadra nella stessa partita.
- Gli aggiornamenti persistenti passano da `FirestoreTrioRepository`.
- Una modifica a risultato o roster può cambiare il rating: preserva ricalcolo e storico.
- Modificando `ScrimmageMatch`, aggiorna serializzazione Firestore e test collegati.
- I provider derivati devono leggere da `matchesProvider`, non mantenere copie dell'archivio.
