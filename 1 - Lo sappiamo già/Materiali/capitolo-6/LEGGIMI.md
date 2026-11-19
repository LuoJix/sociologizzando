# Capitolo 6: i grafici a punti e il confronto fra Trentino e Italia

Questa cartella permette di rifare i due grafici a punti del capitolo 6 e la tabella del confronto fra Trentino e Italia, e di disegnare un grafico a punti con i propri dati, anche senza programmare.

- `grafico_a_punti.xlsx`, il foglio elettronico che disegna il grafico a punti: si scrivono i dati nelle celle gialle, e il grafico si ridisegna da sé;
- `grafici.R`, il programma che disegna i due grafici e li salva come immagini;
- `confronto.R`, il programma che calcola le misure di disuguaglianza della mortalità per titolo di studio, in Trentino e in Italia;
- `equiplot_passi_istruzione.png` e `equiplot_mortalita_trentino_italia.png`, i due grafici come escono dal programma, a colori; accanto, con il nome che finisce in `_bn`, le stesse figure in grigi e con i caratteri più grandi, per la stampa in bianco e nero.

Se è la prima volta, leggere prima il file `LEGGIMI.md` nella cartella principale.

## Il grafico con il foglio elettronico

Per chi non usa R.

1. Aprire `grafico_a_punti.xlsx` con Excel, Numbers o LibreOffice.
2. Scegliere il foglio con il numero di gruppi che serve: «Quattro gruppi», «Tre gruppi» o «Due gruppi». Ognuno contiene già un esempio preso dal libro: la mortalità di Trentino e Italia (quattro titoli di studio), gli stili di vita PASSI (tre titoli di studio), l'obesità per difficoltà economiche (due gruppi).
3. Le celle **gialle** sono i dati: nella colonna A i nomi delle righe del grafico (indicatori, territori o anni); nella riga 5 i nomi dei gruppi, dal più svantaggiato al più favorito; sotto, i valori. Un valore che manca si lascia vuoto. Il grafico si ridisegna da sé.
4. Per aggiungere una riga, inserirne una nuova fra due righe gialle, o sopra l'ultima (clic destro sul numero della riga, poi «Inserisci riga»): così entra da sola nel grafico, mentre una riga scritta sotto l'ultima il grafico non la vede. Se le due celle grigie della riga nuova restano vuote (Excel e LibreOffice non le riempiono, Numbers sì), copiarle dalla riga sopra. Per togliere una riga, eliminarla intera.
5. Il titolo e il nome dell'asse si cambiano con un clic sul grafico, poi sulla scritta.

Le due celle **grigie** di ogni riga calcolano il valore più alto e la distanza fra il più alto e il più basso, che servono a disegnare la linea grigia: non serve toccarle. Il foglio «Istruzioni» ripete questi passi.

Il grafico del foglio elettronico è in verticale: le righe stanno in basso e i valori salgono. È la forma che Excel, Numbers e LibreOffice disegnano allo stesso modo; si legge come quelli del libro, che sono in orizzontale. È a colori; per una versione in grigi, con i caratteri più grandi, adatta alla stampa, c'è il programma in R.

## I grafici con R

1. Aprire RStudio.
2. Menu **File** → **Open File...**, scegliere `grafici.R`.
3. Premere **Source**.

Nella console compare il messaggio «Fatto: i due grafici sono stati salvati nella cartella del programma», con l'elenco dei file. Sono quattro, perché ogni grafico esce a colori e in bianco e nero (`_bn`); i file `.png` si trovano accanto al programma; in RStudio si vedono nel riquadro dei file, a destra, e si aprono con un clic. Non servono pacchetti aggiuntivi.

### Un grafico con i propri dati

In fondo al programma ci sono due blocchi, GRAFICO 1 e GRAFICO 2. Il modo più semplice è cambiare il primo:

```r
passi <- rbind(c(20, 13, 9), c(18, 8, 7), c(11, 10, 9))
```

Ogni `c(...)` dentro `rbind(...)` è una riga del grafico: i valori dei gruppi, dal più svantaggiato al più favorito. Subito sotto si cambiano, sempre fra virgolette, i nomi delle righe (`righe`), i nomi dei gruppi (`gruppi`), il titolo (`titolo`), la fonte (`nota`) e, se serve, il nome del file. Con `xlim = c(0, 25)` si sceglie dove comincia e dove finisce la scala: va allargata se i valori superano 25. Si salva e si preme di nuovo **Source**.

Ogni gruppo ha un colore e una forma (cerchio, triangolo, quadrato, rombo), così il grafico si legge anche stampato in bianco e nero. Se si cambia il numero dei gruppi, si cambia la riga `quali`: con quattro gruppi `quali = 1:4` (come nel GRAFICO 2), con tre `quali = c(1, 3, 4)` (come nel GRAFICO 1), cioè il più scuro, uno chiaro e il più chiaro.

## Il confronto

1. Aprire `confronto.R` in RStudio.
2. Premere **Source**.

Si deve vedere questo:

```text
MORTALITÀ 30-69 ANNI PER TITOLO DI STUDIO, 2022: TRENTINO E ITALIA
-------------------------------------------------------------------
                                               Trentino     Italia
Differenza fra il primo e l'ultimo gruppo          16,3       25,3
Rapporto fra il primo e l'ultimo gruppo             2,1        2,3
Indice di pendenza (morti ogni 10 mila)            19,4       23,4
Indice relativo                                     2,5        2,4
Frazione attribuibile (%)                         -31,4      -31,0
```

L'indice di pendenza è positivo, come in HEAT: per un indicatore da ridurre come la mortalità, un valore positivo vuol dire che pesa di più su chi ha studiato meno.

Questi numeri si vedono se il pacchetto `healthequal` è installato. Senza, il programma salta l'indice relativo e calcola l'indice di pendenza a mano, con una retta invece della curva dell'OMS: viene 19,3 per il Trentino e 24,7 per l'Italia, vicino ma non uguale.

Le misure assolute dicono che in Trentino il divario è più piccolo; quelle relative, che è quasi uguale. Il capitolo 6 spiega perché le due cose sono vere insieme.

Per confrontare un'altra regione con l'Italia: si scaricano i suoi tassi con il programma del capitolo 3, si copiano i quattro valori del 2022 al posto di quelli del Trentino nel **PASSO 1** (con il punto per i decimali: 30.9, non 30,9) e si sostituiscono le quattro popolazioni con quelle della regione (censimento ISTAT, 25-64 anni, sul sito esploradati.istat.it).

## Fonti dei dati

- ISTAT, «Indicatori di mortalità per causa e titolo di studio», 2022.
- ISTAT, censimento permanente della popolazione 2022, popolazione per grado di istruzione ed età (25-64 anni).
- Osservatorio epidemiologico dell'azienda sanitaria trentina (APSS, oggi ASUIT), schede PASSI e PASSI d'Argento 2023-2025.
