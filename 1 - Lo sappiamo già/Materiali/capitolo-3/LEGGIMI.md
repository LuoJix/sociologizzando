# Capitolo 3: la mortalità per titolo di studio

Il capitolo 3 è una mappa delle fonti. Fra queste, la più utile è la tavola dell'ISTAT con i tassi di mortalità per titolo di studio, che esiste per ogni regione e per le due province autonome, anni 2019-2022. Questa cartella contiene un programma che la scarica e la presenta in modo leggibile, per qualunque regione.

- `mortalita_istruzione.R`, il programma;
- `mortalita_istruzione_trentino.csv`, i dati già scaricati per il Trentino e per l'Italia (30-69 anni, maschi e femmine insieme), come esempio: si apre con il foglio elettronico.

Se è la prima volta, leggere prima il file `LEGGIMI.md` nella cartella principale.

## Eseguire il programma

Serve il collegamento a internet: il programma chiede i dati direttamente all'ISTAT. Non servono pacchetti aggiuntivi.

1. Aprire RStudio.
2. Menu **File** → **Open File...**, scegliere `mortalita_istruzione.R`.
3. Premere **Source**.

Dopo qualche secondo («Scarico i dati dall'ISTAT...») nella console compaiono due tabelle, una per il Trentino e una per l'Italia. Quella del Trentino deve cominciare così:

```text
MORTALITÀ PER TITOLO DI STUDIO - Provincia autonoma di Trento - sesso T - età Y30-69
Tasso standardizzato ogni 10.000 abitanti (fra parentesi: numero di morti)

Titolo di studio                   2019             2020             2021             2022       Media
Nessuno o elementare      41,7 (   102)    37,0 (    79)    37,9 (    67)    30,9 (    57)        36,9
Licenza media             26,9 (   252)    29,0 (   278)    30,0 (   274)    29,2 (   260)        28,8
Diploma                   22,4 (   317)    23,2 (   335)    24,6 (   364)    21,1 (   321)        22,8
Laurea                    14,0 (    58)    16,4 (    73)    16,1 (    70)    14,6 (    74)        15,3
```

Come si legge: per ogni titolo di studio e per ogni anno, il tasso di mortalità standardizzato per età (quanti morti ogni 10.000 abitanti, a parità di età) e, fra parentesi, quanti sono stati i morti. L'ultima colonna è la media dei quattro anni. Sotto la tabella il programma calcola quante volte la mortalità di chi ha studiato di meno supera quella dei laureati.

I numeri fra parentesi servono a una cosa importante: se sono piccoli (poche decine), il tasso cambia molto da un anno all'altro per puro caso. Nel Trentino succede ai gruppi estremi. È il motivo per cui conviene guardare la media.

Il programma salva i dati scaricati in un file `.csv` nella stessa cartella, che si apre con il foglio elettronico; il nome dice che cosa contiene, per esempio `mortalita_istruzione_ITD2_T_Y30-69.csv` (territorio, sesso, età, con i codici del PASSO 1). Il file d'esempio `mortalita_istruzione_trentino.csv` è fatto allo stesso modo. Una riga per territorio, titolo di studio e anno, con queste colonne:

| Colonna | Che cosa contiene |
|---|---|
| Territorio | la regione o provincia autonoma scelta, oppure l'Italia |
| Sesso, Età | le scelte del PASSO 1, scritte per esteso |
| Titolo di studio | da «Nessuno o elementare» a «Laurea»; «Tutti» è la popolazione intera |
| Anno | dal 2019 al 2022 |
| Tasso standardizzato ogni 10.000 abitanti | quanti morti ogni 10.000 abitanti, a parità di età (popolazione standard europea), a un decimale |
| Numero di morti | quanti sono stati davvero i morti del gruppo in quell'anno |

Le colonne sono separate dal punto e virgola e i decimali hanno la virgola, come si aspettano Excel, Numbers e LibreOffice in italiano.

## Scegliere un'altra regione, il sesso, l'età

Nel riquadro del programma, al **PASSO 1**, ci sono tre righe:

```r
TERRITORIO <- "ITD2"
SESSO <- "T"
ETA <- "Y30-69"
```

Si cambia quello che c'è fra le virgolette, lasciando le virgolette, si salva (**File** → **Save**) e si preme di nuovo **Source**.

- **Sesso**: `"T"` maschi e femmine insieme, `"M"` maschi, `"F"` femmine.
- **Età**: `"Y30-69"` da 30 a 69 anni, `"Y70-84"` da 70 a 84, `"Y_GE85"` 85 e oltre, `"Y_GE30"` 30 e oltre.
- **Territorio**: i codici sono quelli della tabella qua sotto, e vanno presi da qui. Sono i codici che l'ISTAT usa su tutto il suo portale dei dati. Somigliano a quelli europei di Eurostat, ma per il Nord-est e il Centro sono diversi: chi cercasse in rete il codice del Veneto troverebbe `ITH3`, mentre per l'ISTAT è `ITD3`, e con `ITH3` il programma non trova niente.

| Codice | Territorio | Codice | Territorio |
| --- | --- | --- | --- |
| `ITC1` | Piemonte | `ITE3` | Marche |
| `ITC2` | Valle d'Aosta | `ITE4` | Lazio |
| `ITC3` | Liguria | `ITF1` | Abruzzo |
| `ITC4` | Lombardia | `ITF2` | Molise |
| `ITD1` | Provincia autonoma di Bolzano | `ITF3` | Campania |
| `ITD2` | Provincia autonoma di Trento | `ITF4` | Puglia |
| `ITD3` | Veneto | `ITF5` | Basilicata |
| `ITD4` | Friuli-Venezia Giulia | `ITF6` | Calabria |
| `ITD5` | Emilia-Romagna | `ITG1` | Sicilia |
| `ITE1` | Toscana | `ITG2` | Sardegna |
| `ITE2` | Umbria | | |

Ci sono anche le grandi aree: `ITC` Nord-ovest, `ITD` Nord-est, `ITE` Centro, `ITF` Sud, `ITG` Isole.

## Se l'ISTAT non risponde

Il programma si ferma con il messaggio «L'ISTAT non ha risposto, oppure non ci sono dati per questa scelta». Le cause possibili: manca il collegamento a internet; il servizio dell'ISTAT è momentaneamente lento (si riprova dopo qualche minuto); uno dei codici del PASSO 1 è scritto male (controllare maiuscole, trattini e virgolette).

La stessa tavola si può consultare anche a mano sul sito <https://esploradati.istat.it>, cercando «mortalità per causa e titolo di studio».

## Fonte dei dati

ISTAT, «Indicatori di mortalità per causa e titolo di studio», tavola `39_1_DF_DCIS_IND_MORT_EDU_1`, banca dati esploradati.istat.it.
