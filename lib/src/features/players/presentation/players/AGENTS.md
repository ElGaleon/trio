# Pagina giocatori

Route: `/players`. Elenco ricercabile e filtrabile con accesso a creazione, dettaglio, modifica e cancellazione.

## Stato

- `filteredPlayersProvider` combina ricerca, ruolo e linea preferita.
- I controller locali sincronizzano input e provider e devono essere rilasciati in `dispose`.
- Le card usano i dati persistiti e navigano tramite `AppRoutes`.

## Modifiche

- Mantieni ricerca case-insensitive e filtri combinabili.
- Passa l'oggetto esistente come `extra` solo per velocizzare la modifica; l'ID resta la fonte stabile.
- Conferma la cancellazione e delegala al repository.
- Usa lo stato vuoto condiviso quando archivio o filtro non producono risultati.
