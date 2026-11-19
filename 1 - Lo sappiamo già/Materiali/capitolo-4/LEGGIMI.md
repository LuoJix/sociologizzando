# Capitolo 4: reddito e mortalità per territorio

Questa cartella permette di rifare i calcoli del capitolo 4: i comuni di una provincia, ordinati dal più povero al più ricco e divisi in cinque gruppi con circa lo stesso numero di abitanti (i *quintili*), e per ogni gruppo il rapporto standardizzato di mortalità (SMR).

Contiene:

- `quintili.R`, il programma che fa i conti;
- `comuni_TN.csv`, la tabella dei 166 comuni trentini già pronta (abitanti, decessi 2022-2024, reddito dichiarato);
- `prepara_dati.R`, il programma che costruisce la tabella per un'altra provincia;
- `dati_originali`, la cartella con i file dell'ISTAT e del Ministero dell'Economia da cui è stata costruita la tabella trentina.

Se è la prima volta, leggere prima il file `LEGGIMI.md` nella cartella principale: spiega come installare R e RStudio, come dare il permesso necessario sul Mac e come eseguire un programma.

## Primo passo: i conti sul Trentino

Non serve installare niente oltre a R.

1. Aprire RStudio.
2. Menu **File** → **Open File...**, scegliere il file `quintili.R` di questa cartella.
3. Premere **Source**.

Nella console si deve vedere questo:

```
RISULTATI: mortalità 2022-2024 per quintile di reddito dei comuni, TN
(SMR: 100 = mortalità uguale alla media della provincia, a parità di età e sesso)

Quintile  Comuni  Abitanti  Reddito/ab.   SMR  (int. conf.)    SMR <65  (int. conf.)
    1       62    108719      19728 €   99,4  ( 95,9-103,0)    105,0  ( 93,9-117,0)
    2       31    108001      20922 €  102,2  ( 98,6-105,8)     96,7  ( 86,1-108,3)
    3       24    114173      21747 €   99,0  ( 95,7-102,3)     98,5  ( 88,0-110,0)
    4       33     68963      22939 €  105,3  (100,8-110,0)    109,9  ( 95,7-125,6)
    5       16    143140      24344 €   97,3  ( 94,4-100,3)     95,0  ( 85,7-105,0)

Indice di pendenza, tutte le età:     2,3 punti di SMR (positivo: si muore di più nei comuni più poveri)
Indice di pendenza, sotto i 65 anni:   6,7 punti
```

Il programma salva gli stessi risultati anche nel file `risultati_quintili_TN.csv`, che si apre con il foglio elettronico (le colonne sono separate dal punto e virgola e i decimali hanno la virgola, come si aspettano Excel, Numbers e LibreOffice in italiano). Le colonne sono le stesse della tabella qui sopra, con i nomi per esteso:

| Colonna | Che cosa contiene |
|---|---|
| Quintile (1 = più povero) | il gruppo di comuni, dal più povero (1) al più ricco (5) |
| Comuni, Abitanti | quanti comuni e quanti abitanti ci sono nel gruppo |
| Reddito per abitante (euro) | il reddito complessivo dichiarato nei comuni del gruppo, diviso per i loro abitanti |
| SMR tutte le età | la mortalità del gruppo rispetto alla media della provincia (100 = come la media) |
| SMR tutte le età, intervallo da / intervallo a | i due estremi dell'intervallo di confidenza al 95%: il valore vero sta quasi certamente fra questi due numeri |
| SMR sotto i 65 anni, e i suoi «intervallo da» e «intervallo a» | le stesse tre cose, contando solo i morti sotto i 65 anni |

Il reddito è arrotondato all'euro e l'SMR a un decimale: i decimali in più non direbbero niente di vero, perché l'incertezza, come mostra l'intervallo, è di parecchi punti. Il foglio elettronico può mostrare 103 invece di 103,0: è lo stesso numero.

Come si legge la tabella: l'SMR dice quanto si muore in un gruppo di comuni rispetto alla media della provincia, tenendo conto che alcuni comuni hanno più anziani di altri (100 = come la media; 110 = il 10% in più). Fra parentesi c'è l'intervallo di confidenza: se gli intervalli di due quintili si sovrappongono, la differenza fra loro potrebbe essere dovuta al caso.

## Secondo passo: un'altra provincia

Qui servono tre file da scaricare e un pacchetto in più. Con calma, si fa in mezz'ora.

### 1. Installare il pacchetto readxl (una volta sola)

Serve per leggere i file Excel dell'ISTAT. Aprendo `prepara_dati.R` in RStudio compare in alto una barra gialla («Package readxl required but is not installed»): basta fare clic su **Install**. In alternativa si scrive nella console:

```r
install.packages("readxl")
```

### 2. Scaricare i tre file

Si mettono tutti nella cartella `dati_originali`, al posto di quelli del Trentino (si possono spostare altrove o cancellare).

**a) La popolazione della provincia** (ISTAT). L'indirizzo ha questa forma:

```
https://demo.istat.it/data/posas/POSAS_2023_it_022_Trento.zip
```

Per un'altra provincia si cambiano il codice e il nome: per Bologna, per esempio, `POSAS_2023_it_037_Bologna.zip`. Il file scaricato è un `.zip`: un doppio clic lo apre e ne esce un file `.csv`, che va messo in `dati_originali`. Il numero di tre cifre nel nome (`022`, `037`) è il codice ISTAT della provincia: servirà al passo 3.

Se l'indirizzo non funziona (per esempio per un nome di provincia scritto diversamente), il file si trova sul sito <https://demo.istat.it>, alla voce della popolazione residente per età, sesso e stato civile, anno 2023.

**b) I decessi per comune** (ISTAT), un unico file per tutta Italia:

```
https://www.istat.it/storage/dati_mortalita/giugno-2026/decessi-comunali-mese-provvisori-3.zip
```

È grande (46 MB). Aperto con un doppio clic, contiene un file Excel per ogni anno dal 2011. Servono quelli del **2022**, del **2023** e del **2024**: si mettono in `dati_originali`. Il nome dei file è lungo («tavola riepilogativa_decessi comunali per mese, sesso e classe di età_2022.xlsx») e sul Mac la «à» può comparire storpiata: non importa, il programma li riconosce dall'anno.

**c) I redditi per comune** (Ministero dell'Economia e delle Finanze), un unico file per tutta Italia:

```
https://www1.finanze.gov.it/finanze/analisi_stat/public/v_4_0_0/contenuti/Redditi_e_principali_variabili_IRPEF_su_base_comunale_CSV_2024.zip
```

Aperto con un doppio clic, contiene un file `.csv` da mettere in `dati_originali`.

Alla fine, in `dati_originali` ci devono essere cinque file: uno della popolazione, tre dei decessi, uno dei redditi.

### 3. Indicare la provincia

Si apre `prepara_dati.R` in RStudio (**File** → **Open File...**). Al **PASSO 1** ci sono due righe:

```r
CODICE_PROVINCIA <- "022"
SIGLA_PROVINCIA  <- "TN"
```

Si sostituiscono il codice (quello di tre cifre del file della popolazione) e la sigla della provincia (quella delle targhe), lasciando le virgolette. Per Bologna: `"037"` e `"BO"`. Si salva (**File** → **Save**).

Si apre poi `quintili.R` e, al **PASSO 1**, si cambia allo stesso modo la sigla, e si salva:

```r
SIGLA_PROVINCIA <- "BO"
```

### 4. Eseguire i due programmi, uno dopo l'altro

1. Con `prepara_dati.R` aperto in RStudio, si preme **Source**. Il programma scrive che cosa sta leggendo («Leggo la popolazione...», «Leggo i decessi del 2022...») e alla fine dice quanti comuni, abitanti e decessi ha trovato. Ci vuole meno di un minuto.
2. Si passa a `quintili.R` (la sua scheda è in alto, accanto a quella di `prepara_dati.R`) e si preme **Source**. Compare la tabella dei quintili della nuova provincia.

Se `prepara_dati.R` si ferma con un messaggio «Non trovo...», manca uno dei file del passo 2, oppure il codice della provincia non corrisponde al file della popolazione.

## Un'avvertenza sui capoluoghi grandi

Un comune non si può dividere fra due quintili. Se il capoluogo ha più di un quinto degli abitanti della provincia, occupa da solo un quintile intero, e i gruppi vicini restano sbilanciati. In Trentino succede con Trento (118.000 abitanti su 543.000). Nella provincia di Bologna è più evidente: Bologna, con 389.000 abitanti su un milione, è da sola il quarto quintile, e il quinto contiene un solo comune. In questi casi i risultati vanno letti sapendo che un quintile coincide con una città.

## Fonti dei dati

- ISTAT, popolazione residente per età, sesso e stato civile al 1° gennaio 2023 (demo.istat.it).
- ISTAT, decessi comunali per mese, sesso e classe d'età, 2022-2024, rilascio di giugno 2026 (dati provvisori per gli anni più recenti).
- Ministero dell'Economia e delle Finanze, Dipartimento delle Finanze, redditi e principali variabili IRPEF su base comunale, anno d'imposta 2024.
