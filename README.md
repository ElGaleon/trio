# SKRIM

App Flutter per gestire roster, partite di Ultimate Frisbee, ranking Elo e statistiche live collaborative.

## Architettura

- Flutter + Riverpod per UI, stato e provider derivati.
- Firebase Auth gestisce l'accesso email/password e Google.
- Firestore persiste giocatori, partite, impostazioni e statistiche live.
- Le statistiche live sono collaborative: più utenti autenticati possono aprire la stessa partita e vedere gli aggiornamenti in realtime.
- La multi-tenancy usa organizzazioni Firestore: dopo il login l'utente lavora dentro l'organizzazione selezionata o auto-selezionata quando è l'unica disponibile.
- `go_router` centralizza tutte le rotte in `lib/src/routing/app_router.dart`.

## Login

Il flusso attivo è Firebase Auth -> app. Dopo credenziali valide l'utente entra direttamente nella ranking.

## Firebase

I file di configurazione sono generati da FlutterFire:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `macos/Runner/GoogleService-Info.plist`

## Verifica

Per una modifica completa:

```sh
dart format lib test
flutter analyze
flutter test
```

Per modifiche locali, eseguire almeno `flutter analyze` e il test mirato.
