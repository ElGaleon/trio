# Feature giocatori

Gestisce anagrafica, immagini, filtri, ranking Elo e analisi individuali.

## Strati

- `domain/`: giocatore, ruolo, linea preferita e modelli analitici.
- `application/player_providers.dart`: archivio Firestore e filtri.
- `application/player_form_provider.dart`: creazione, modifica e immagine.
- `application/player_stats_provider.dart`: statistiche aggregate e dettaglio.
- `presentation/`: ranking, elenco, form, dettaglio e statistiche.

## Invarianti

- `Player.id` è il riferimento usato dalle partite: non cambiarlo durante una modifica.
- Il rating deriva dalle partite tramite `FirestoreTrioRepository`; non modificarlo direttamente nella UI.
- La cancellazione deve considerare i riferimenti nelle partite.
- Le immagini persistite devono sopravvivere alla chiusura dell'app.
- Modificando `Player`, aggiorna serializzazione Firestore e test collegati.
