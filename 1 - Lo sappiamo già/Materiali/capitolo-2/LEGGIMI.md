# Capitolo 2: le quattro misure

Questa cartella permette di rifare i calcoli del capitolo 2: differenza, rapporto, indice di pendenza e frazione attribuibile per i sedentari trentini divisi per titolo di studio.

Contiene due file, che danno gli stessi risultati:

- `misure.xlsx`, il foglio elettronico;
- `misure.R`, il programma per R.

C'è poi un terzo programma, `grafico_retta.R`, che disegna il grafico della retta dell'indice di pendenza (`retta_pendenza.png`, lo stesso del capitolo; accanto, `retta_pendenza_bn.png`, in grigi e con i caratteri più grandi, per la stampa in bianco e nero). Si usa come gli altri: aperto in RStudio, pulsante Source. Non servono pacchetti aggiuntivi. In fondo stampa anche l'indice (14,1 punti) e i due capi della retta (20,5 e 6,4); l'immagine compare nella stessa cartella. Per disegnarlo con i propri dati si cambiano le tre righe con gruppi, popolazioni e valori, in testa al programma.

Se è la prima volta, leggere prima il file `LEGGIMI.md` nella cartella principale: spiega come installare R e RStudio e come dare il permesso necessario sul Mac.

## Strada A: il foglio elettronico

1. Aprire `misure.xlsx` con Excel, Numbers o LibreOffice.
2. Nel foglio **Misure** ci sono tre righe, una per gruppo, dal più svantaggiato al più favorito.
   - Le celle **gialle** sono i dati: popolazione e percentuale di sedentari.
   - Le celle **grigie** sono i passaggi del calcolo.
   - Le celle **azzurre** sono i risultati.
3. Facendo clic su una cella grigia o azzurra si vede la formula nella barra in alto. Per esempio, la frazione attribuibile è `=(C7-C10)/C10`: il valore dei laureati (C7) meno la media (C10), diviso la media.
4. Per provare con altri dati, si cambiano le celle gialle: tutto il resto si ricalcola.

Risultati che si devono vedere con i dati del Trentino:

| Misura | Valore |
|---|---|
| Media del territorio | 13,4 |
| Differenza | 11,0 |
| Rapporto | 2,2 |
| Indice di pendenza | 14,1 |
| Frazione attribuibile | −33,0% |

## Strada B: R con RStudio

1. Aprire RStudio.
2. Menu **File** → **Open File...**, scegliere il file `misure.R` di questa cartella. Si apre in alto a sinistra: i commenti spiegano ogni passo.
3. Premere **Source**, in alto a destra del riquadro del programma.

Nella console, in basso a sinistra, si deve vedere questo:

```
RISULTATI: sedentari per titolo di studio, Trentino
---------------------------------------------------
  Fino alla licenza media    20,0%   quota della popolazione  21,4%
  Diploma                    13,0%   quota della popolazione  51,8%
  Laurea                      9,0%   quota della popolazione  26,8%
  Media del territorio       13,4%

  Differenza                   11,0 punti
  Rapporto                      2,2 volte
  Indice di pendenza           14,1 punti
  Frazione attribuibile       -33,0%

  (La sedentarietà è un indicatore sfavorevole: come nei programmi dell'OMS,
   l'indice di pendenza è positivo quando il problema pesa di più su chi ha
   studiato meno.)

CONTROLLO con il pacchetto dell'OMS (healthequal)
------------------------------------------------
  Indice di pendenza           14,1 punti
  Indice relativo               2,9 volte (fondo della scala rispetto alla cima)
```

Se il pacchetto `healthequal` non è installato, l'ultima parte è sostituita da un messaggio che spiega come installarlo; i risultati sopra restano validi.

### Provare con i propri dati

Nel riquadro di RStudio in cui è aperto `misure.R`, al **PASSO 1**, ci sono fra le altre queste due righe di numeri:

```r
sedentari   <- c(20, 13, 9)
popolazione <- c(61361, 148766, 76964)
```

Si cambiano solo i numeri dentro le parentesi, lasciando le virgole fra un numero e l'altro. Attenzione: dentro R il separatore decimale è il punto (12.5, non 12,5); la virgola separa un numero dall'altro. Si salva (menu **File** → **Save**) e si preme di nuovo **Source**.

## Fonti dei dati

- Sedentari: PASSI 2023-2024, Osservatorio epidemiologico APSS, scheda *Ogni movimento conta!*, Trentino, 18-64 anni.
- Popolazione per titolo di studio: ISTAT, censimento permanente della popolazione 2024, Provincia autonoma di Trento, 25-64 anni (tavola «Popolazione residente di 9 anni e più per grado di istruzione ed età», esploradati.istat.it).
