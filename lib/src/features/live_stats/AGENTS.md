# Feature statistiche live

Configura una partita statistica e registra eventi, lineup, pause, pull, sostituzioni e risultato in tempo reale.

## Strati

- `domain/`: stato del setup e riepiloghi live.
- `application/stats_match_setup_provider.dart`: stato e creazione della partita; scrive su Firestore quando l'utente è autenticato.
- `application/live_stats_service.dart`: sede per mutazioni live, undo e chiusura.
- `presentation/stats_match_setup/`: wizard iniziale.
- `presentation/live_stats/`: console durante la partita.

## Invarianti

- Ogni evento registrato deve lasciare partita e statistiche coerenti.
- Undo deve invertire l'ultima azione persistita senza perdere dati precedenti.
- Timer e scadenze derivano da timestamp persistiti, non da soli contatori UI.
- Lineup e sostituzioni devono contenere soltanto giocatori appartenenti al roster corretto.
- Le scritture passano da `LiveStatsService` o dal notifier di setup.
- Per collaborazione real-time completa, le mutazioni evento-per-evento devono usare `FirestoreTrioRepository.updateMatchTransaction`.
