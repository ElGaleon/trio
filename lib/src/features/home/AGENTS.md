# Home e navigazione

`HomeScreen` è lo shell persistente delle cinque sezioni principali: ranking, partite, giocatori, statistiche e impostazioni.

## Flusso

- Riceve `StatefulNavigationShell` da `app_router.dart`.
- La destinazione selezionata deve restare allineata all'ordine dei branch nel router.
- Il cambio tab usa `goBranch`; non creare navigator paralleli.
- Le pagine figlie mantengono il proprio stato grazie a `StatefulShellRoute.indexedStack`.

## Modifiche

- Se aggiungi, rimuovi o riordini una destinazione, aggiorna nello stesso cambiamento anche i branch del router.
- Mantieni qui soltanto layout e navigazione globale; logica e azioni appartengono alla feature di destinazione.
