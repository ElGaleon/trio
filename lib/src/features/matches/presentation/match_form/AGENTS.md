# Pagina creazione e modifica partita

Route: `/matches/new` oppure `/matches/:matchId/edit`. Wizard per configurare squadre, presenze e risultato.

## Stato e flusso

- `matchFormProvider(matchId)` contiene tutto lo stato del wizard.
- Senza ID crea una partita; con ID carica e aggiorna quella esistente.
- I passaggi sono configurazione, selezione giocatori, presenze e punteggio.
- `recentMatchTeamsProvider` consente di riusare roster validi delle partite odierne.
- Il salvataggio passa da `MatchFormNotifier.save`.

## Invarianti

- Non duplicare un giocatore tra squadra A e B.
- Conserva gli eventi e le impostazioni statistiche quando modifichi una partita esistente.
- Valida roster e campi prima di avanzare o salvare.
- Le regole del wizard appartengono al notifier; i widget dei singoli step restano presentazionali.
