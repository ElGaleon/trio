# SKRIM

App Flutter per gestire giocatori, partite di Ultimate Frisbee, ranking Elo e statistiche live.

## Architettura

- `lib/main.dart` inizializza Firebase prima di avviare l'app.
- `lib/src/routing/app_router.dart` è l'unica fonte delle rotte `go_router`.
- `lib/src/features/` contiene feature verticali divise in `domain`, `data`, `application` e `presentation`.
- `lib/src/shared/` contiene widget realmente condivisi; non spostare qui componenti usati da una sola pagina.
- Riverpod gestisce stato e reattività; Firestore persiste giocatori, partite, impostazioni e statistiche live.
- Non usare API Riverpod legacy (`flutter_riverpod/legacy.dart`, `StateProvider`, `StateNotifierProvider`, ecc.); usa i provider supportati da Riverpod 3, come `NotifierProvider`, `AsyncNotifierProvider`, `StreamProvider` e helper moderni locali.
- La multi-tenancy usa organizzazioni Firestore: dopo il login Firebase l'utente lavora dentro l'organizzazione selezionata o auto-selezionata quando è l'unica disponibile.
- `FirestoreSkrimRepository` è il punto comune per modifiche persistenti a partite, giocatori e rating.

## Regole di modifica

- Riusa provider, repository e widget esistenti prima di crearne altri.
- Mantieni la logica di dominio fuori dai widget; la UI legge provider e invoca notifier o servizi.
- Quando cambia un modello persistito, aggiorna serializzazione Firestore, test e regole se necessario.
- Aggiungi una rotta solo in `app_router.dart` e usa sempre `AppRoutes`.
- Mantieni testi UI e messaggi in italiano.
- Non modificare file generati nelle directory di piattaforma.

## Verifica

Esegui, nell'ordine:

```sh
dart format lib test
flutter analyze
flutter test
```

Per una modifica locale, esegui almeno il test mirato e `flutter analyze`.
