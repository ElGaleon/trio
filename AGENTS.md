# Trio

App Flutter per gestire giocatori, partite di Ultimate Frisbee, ranking Elo e statistiche live.

## Architettura

- `lib/main.dart` inizializza Hive, registra gli adapter e apre i box prima di avviare l'app.
- `lib/src/routing/app_router.dart` è l'unica fonte delle rotte `go_router`.
- `lib/src/features/` contiene feature verticali divise in `domain`, `data`, `application` e `presentation`.
- `lib/src/shared/` contiene widget realmente condivisi; non spostare qui componenti usati da una sola pagina.
- Riverpod gestisce stato e reattività; Hive persiste giocatori, partite e impostazioni.
- `EloRepository` è il punto comune per modifiche a partite, giocatori e rating.

## Regole di modifica

- Riusa provider, repository e widget esistenti prima di crearne altri.
- Mantieni la logica di dominio fuori dai widget; la UI legge provider e invoca notifier o servizi.
- Quando cambia un modello Hive, conserva la compatibilità dei field index nell'adapter.
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
