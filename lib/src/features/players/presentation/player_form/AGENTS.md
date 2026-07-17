# Pagina creazione e modifica giocatore

Route: `/players/new` oppure `/players/:playerId/edit`.

## Stato e flusso

- `playerFormProvider(playerId)` inizializza e salva il form.
- Il form gestisce nome, numero, ruolo, linea preferita, esterno e immagine.
- Le immagini possono arrivare da galleria, fotocamera o file e vengono copiate nello storage applicativo.
- Il salvataggio conserva ID e dati storici del giocatore esistente.

## Invarianti

- Valida nome e numero prima del salvataggio.
- Non scrivere percorsi temporanei di picker nel modello persistito.
- Elimina o sostituisci immagini solo attraverso il notifier.
- Gestisci permessi e annullamento picker senza trattarli come errori fatali.
