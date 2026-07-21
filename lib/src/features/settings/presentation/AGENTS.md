# Pagina impostazioni

Route: `/settings`. Modifica preferenze applicative e configurazione del calcolo statistico.

## Flusso

- `settingsFormProvider` crea una copia modificabile delle impostazioni correnti.
- I controller testuali riflettono lo stato del form e vengono rilasciati in `dispose`.
- `save()` valida, scrive su Firestore, invalida i provider e ricalcola i rating.
- `CustomStatEditDialog` crea o modifica una statistica; la sezione dedicata gestisce elenco e preferiti.

## Modifiche

- Non persistere a ogni battuta: salva soltanto con l'azione esplicita.
- Mostra un errore comprensibile quando la validazione fallisce.
- Mantieni tema `system/light/dark` allineato agli indici interpretati da `TrioApp`.
- Per nuovi campi, aggiorna insieme modello, stato form, notifier, UI e serializzazione Firestore.
