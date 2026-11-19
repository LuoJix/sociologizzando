# Capitolo 5: stili di vita per titolo di studio e condizione economica

Questa cartella permette di rifare i calcoli del capitolo 5 e mostra com'è fatto un file per HEAT Plus, il programma dell'Organizzazione mondiale della sanità.

- `passi_trentino_heat.csv`, i dati PASSI trentini (sedentarietà e obesità, per titolo di studio e per difficoltà economiche), scritti nel formato richiesto da HEAT Plus;
- `misure_passi.R`, il programma che legge quel file e calcola le misure di disuguaglianza per ogni indicatore.

Se è la prima volta, leggere prima il file `LEGGIMI.md` nella cartella principale.

## Guardare il file per HEAT

Il file `passi_trentino_heat.csv` si apre con il foglio elettronico (Excel, Numbers, LibreOffice). Ogni riga è un gruppo: per esempio «adulti di 18-64 anni sedentari, laureati». Le colonne sono quelle che HEAT Plus richiede, e il capitolo 5 le spiega una per una. Le più importanti:

| Colonna | Che cosa contiene |
| --- | --- |
| `indicator_name` | il nome dell'indicatore |
| `dimension` | la dimensione sociale (Istruzione, Difficoltà economiche) |
| `subgroup` | il gruppo |
| `estimate` | il valore del gruppo (la percentuale) |
| `population` | quante persone ci sono nel gruppo (vuota quando non si conosce) |
| `favourable_indicator` | 0 se l'indicatore è da ridurre (come sedentarietà e obesità), 1 se è da aumentare |
| `ordered_dimension` | 1 se i gruppi hanno un ordine (licenza media, diploma, laurea), 0 se no |
| `subgroup_order` | il posto del gruppo nella fila: 1 al più svantaggiato |
| `reference_subgroup` | per le dimensioni con due soli gruppi: 1 al gruppo di riferimento |

Conviene guardarlo prima di eseguire il programma: è lo stampo da copiare per preparare i propri dati.

## Eseguire il programma

1. Aprire RStudio.
2. Menu **File** → **Open File...**, scegliere `misure_passi.R`.
3. Premere **Source**.

Nella console compare un blocco per ogni indicatore e ogni dimensione. Il primo deve essere questo:

```text
Adulti 18-64 sedentari (%) - per istruzione
   Fino alla licenza media       20,0%
   Diploma                       13,0%
   Laurea                         9,0%
   Differenza                    11,0 punti
   Rapporto                       2,2 volte
   Indice di pendenza (OMS)      14,1 punti
   Indice relativo (OMS)          2,9 volte
   Frazione attribuibile        -33,0%
```

Per le difficoltà economiche il programma calcola solo differenza e rapporto, e lo spiega: le altre misure richiedono la popolazione di ogni gruppo, che le schede PASSI non danno.

L'indice di pendenza è positivo, come in HEAT: per un indicatore da ridurre, come la sedentarietà o l'obesità, un valore positivo vuol dire che il problema pesa di più su chi sta in fondo alla scala sociale.

Se il pacchetto `healthequal` non è installato, il programma calcola l'indice di pendenza a mano e salta l'indice relativo, avvertendo come installarlo. Il calcolo a mano usa una retta, mentre l'OMS usa una curva (un modello statistico che tiene conto del fatto che una percentuale non può scendere sotto lo zero né superare il cento): il risultato è vicino ma non sempre uguale. Per i sedentari coincide (14,1); per l'obesità degli adulti viene 13,5 invece di 12,8, per quella degli anziani 2,6 invece di 2,4.

## Provare con i propri dati

1. Fare una copia di `passi_trentino_heat.csv` e tenerla da parte: il programma legge sempre il file con questo nome.
2. Aprire `passi_trentino_heat.csv` con il foglio elettronico e cambiare le righe: i propri indicatori, i propri gruppi, i propri valori. Le regole: una riga per gruppo; in ogni indicatore i gruppi di una dimensione ordinata numerati da 1 (il più svantaggiato) in su in `subgroup_order`; `population` riempita se la si conosce.
3. Salvare nel formato CSV, con lo stesso nome:
   - in **Numbers**: **File** → **Esporta in** → **CSV...**, codifica **Unicode (UTF-8)**;
   - in **Excel**: **File** → **Salva con nome**, formato **CSV UTF-8 (delimitato da virgole)**;
   - in **LibreOffice**: **File** → **Salva con nome**, tipo **Testo CSV**, poi confermare il formato.

   Il foglio elettronico in italiano può separare le colonne con il punto e virgola e usare la virgola per i decimali: il programma riconosce da solo questo formato.
4. Eseguire di nuovo il programma con **Source**.

## Fonti dei dati

- Osservatorio epidemiologico dell'azienda sanitaria trentina, schede PASSI e PASSI d'Argento: *Ogni movimento conta!* (APSS, 2025; attività fisica, dati 2023-2024) e *Alimentazione, sovrappeso e obesità in Trentino* (ASUIT, 2026; dati 2024-2025). L'obesità dei laureati adulti (7%) è ricavata per differenza dal grafico della scheda, dove la cifra non è stampata.
- Popolazione per titolo di studio: ISTAT, censimento permanente 2024, Provincia autonoma di Trento; 25-64 anni per gli adulti, 65 anni e oltre per gli anziani (le classi più vicine a quelle di PASSI).
- Formato del file: OMS, *HEAT Plus User Manual*, versione 7.0, 2026.
