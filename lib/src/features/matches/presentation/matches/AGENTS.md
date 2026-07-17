# Pagina partite

Route: `/matches`. Mostra le partite archiviate in vista elenco o calendario.

## Stato e flusso

- `matchesProvider` espone l'archivio completo.
- `filteredMatchesProvider` applica l'intervallo di date alla vista elenco.
- La vista calendario usa mese, giorno selezionato ed espansione dai provider dedicati.
- Le azioni aprono creazione partita, setup statistiche, dettaglio, modifica o eliminazione.

## Modifiche

- Mantieni sincronizzati selezione del giorno, mese visibile e cambio vista.
- Metti i calcoli di calendario in `calendar_utils.dart`; lascia ai widget solo rendering e interazioni.
- Riusa `MatchCard`, stati vuoti e controlli condivisi.
- Testa i limiti inclusivi dei filtri data quando ne cambi la logica.
