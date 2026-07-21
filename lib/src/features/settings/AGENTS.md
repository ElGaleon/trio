# Feature impostazioni

Gestisce tema, parametri Elo, pesi statistici, statistiche personalizzate e preferiti.

## Strati

- `domain/AppSettings` contiene valori persistiti e default.
- `domain/SettingsFormState` contiene stringhe e modifiche non ancora salvate.
- `application/settings_provider.dart` valida, persiste e avvia il ricalcolo Elo.
- `presentation/` contiene pagina, sezioni e dialog delle statistiche personalizzate.

## Invarianti

- K factor, rating iniziale e pesi devono essere numeri validi prima del salvataggio.
- Un cambio ai parametri Elo richiede il ricalcolo dei rating.
- Gli ID delle statistiche personalizzate restano stabili durante la modifica.
- La rimozione di una statistica deve rimuoverla anche dai preferiti.
- Nuovi campi persistiti richiedono default e serializzazione Firestore.
