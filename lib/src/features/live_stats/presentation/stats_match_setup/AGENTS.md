# Pagina setup statistiche

Route: `/matches/new_stats`. Wizard per creare una partita con tracciamento live.

## Flusso

- `statsMatchSetupProvider` inizializza valori predefiniti, giocatori e statistiche dalle impostazioni.
- Gli step raccolgono dettagli partita, regole, roster, presenti e metriche abilitate.
- Il flusso cambia tra partita interna e avversario esterno.
- `startMatch()` persiste la partita e restituisce l'ID usato per aprire la console live.

## Invarianti

- Prima dell'avvio devono esserci abbastanza giocatori presenti per il formato scelto.
- I roster A e B restano disgiunti.
- Le statistiche personalizzate e preferite provengono da `AppSettings`.
- Mantieni validazione e transizioni nel notifier o nella screen; i controlli locali emettono soltanto valori.
