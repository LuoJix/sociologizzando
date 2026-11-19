# Lo sappiamo già: i materiali

Questa raccolta accompagna il libro *Lo sappiamo già. Misurare le disuguaglianze di salute con dati pubblici e strumenti gratuiti*, primo volume della collana Sociologizzando. Contiene i dati, i fogli elettronici e i programmi che servono per rifare tutti i calcoli del libro, sul Trentino o sul proprio territorio.

Non serve saper programmare. Le istruzioni sono scritte per chi non ha mai usato un programma di questo tipo, e dicono, passo per passo, che cosa fare e che cosa si deve vedere.

## Che cosa c'è

Una cartella per ogni capitolo che ha dei calcoli da rifare, dal 2 al 6 (`capitolo-2`, `capitolo-3` e così via). In ogni cartella:

- un file `LEGGIMI.md` con le istruzioni di quel capitolo;
- quando serve, un foglio elettronico (`.xlsx`), che si apre con Excel, Numbers o LibreOffice;
- quando serve, un programma in R (`.R`) e i file di dati (`.csv`).

## Due strade

Per quasi tutti i capitoli si può scegliere.

- **Il foglio elettronico.** Non bisogna installare niente, se si ha già Excel, Numbers o LibreOffice (gratuito, da <https://it.libreoffice.org>). Le formule sono visibili cella per cella: è la strada migliore per capire il calcolo.
- **R con RStudio.** R è un programma gratuito per la statistica, usato in tutto il mondo: fa i calcoli. RStudio, anch'esso gratuito, è la finestra da cui lo si usa comodamente: mostra il programma, i risultati e i file, e lo esegue con un pulsante. Si installano una volta tutti e due (sotto si spiega come). È la strada per i calcoli più lunghi e per usare il pacchetto dell'Organizzazione mondiale della sanità, che contiene le stesse formule del suo programma HEAT.

Si può cominciare dal foglio elettronico e passare a R quando si vuole.

## Scaricare i materiali

Da Zenodo, l'archivio pubblico che conserva i materiali in modo permanente: nella pagina del deposito, [indirizzo dei materiali da completare], si scarica il file `.zip`. Un doppio clic lo apre e crea una cartella con tutto il contenuto. È l'indirizzo stampato nel libro, nella pagina «I materiali», e porta sempre alla versione più recente.

Da GitHub: nella pagina della raccolta, <https://github.com/LuoJix/sociologizzando>, si fa clic sul pulsante verde **Code** e poi su **Download ZIP**, e si apre il file `.zip` allo stesso modo.

La raccolta è di tutta la collana Sociologizzando, e contiene anche i materiali degli altri volumi: quelli di questo libro stanno nella cartella `1 - Lo sappiamo già`, sotto `Materiali`. Conviene spostare la cartella in un posto facile da ritrovare, per esempio in Documenti.

## Installare R e RStudio (una volta sola)

Prima R, poi RStudio: RStudio ha bisogno di R per funzionare.

**R**

1. Si va su <https://cran.r-project.org>.
2. Si sceglie il proprio sistema: **Download R for macOS** oppure **Download R for Windows**.
3. Sul Mac ci sono due versioni. Per sapere quale scegliere: menu Apple (la mela in alto a sinistra) → **Informazioni su questo Mac**. Se alla voce «Chip» c'è scritto «Apple M» seguito da un numero, si scarica la versione che nel nome contiene **arm64**; se c'è scritto «Intel», quella che contiene **x86_64**.
   Su Windows si sceglie **base** e poi il collegamento per scaricare.
4. Si apre il file scaricato e si segue l'installazione come per qualunque programma, accettando le scelte proposte.

**RStudio**

1. Si va su <https://docs.posit.co/ide/user/download.html>, la pagina «Download RStudio» di Posit, l'azienda che lo distribuisce. La pagina ricorda che serve R: è già installato.
2. Nella sezione «Recommended for you» la pagina riconosce da sola il sistema e propone il file giusto. Altrimenti, sotto «RStudio Desktop», si sceglie la riga del proprio sistema: per il Mac è «macOS 15+», un solo file per tutti i Mac recenti, che finisce in `.dmg`. Il pulsante «Download Positron», accanto, è un altro programma: non serve.
3. Si installa come qualunque programma. Sul Mac: si apre il file scaricato e si trascina l'icona di RStudio nella cartella Applicazioni.

## Un permesso da dare, sul Mac

Il Mac protegge le cartelle Documenti, Scrivania e iCloud Drive: un programma può leggerne i file solo se ha il permesso. Senza permesso, RStudio apre il programma ma non riesce a leggere i dati che stanno accanto, e si ferma con il messaggio `Operation not permitted`.

Il permesso si dà una volta sola, così:

1. si chiude RStudio;
2. si apre **Impostazioni di Sistema** (dal menu Apple) → **Privacy e sicurezza** → **File e cartelle**. La voce «File e cartelle» sta nella parte destra della finestra, nell'elenco che comincia con «Servizi di localizzazione», «Contatti», «Calendari»;
3. si cerca **RStudio** e si attiva l'interruttore della cartella in cui si sono messi i materiali (Cartella Documenti, Scrivania o iCloud Drive);
4. se RStudio non compare in quell'elenco, si va invece in **Privacy e sicurezza** → **Accesso completo al disco**, si preme **+** in fondo all'elenco, si sceglie RStudio in Applicazioni e si attiva l'interruttore (il Mac chiede la password);
5. si riapre RStudio. Se il Mac chiede «RStudio vorrebbe accedere ai file...», si risponde **Consenti**.

Su Windows questo passo non serve.

## Com'è fatto RStudio

Aprendo RStudio, la finestra è divisa in riquadri:

- **in basso a sinistra, la console**: qui R scrive i risultati, e qui si possono scrivere istruzioni. Il segno `>` all'inizio della riga si chiama *prompt*: vuol dire che R aspetta un'istruzione. Si scrive (o si incolla) l'istruzione dopo il `>` e si preme **Invio**;
- **in alto a sinistra, il programma** aperto (compare quando se ne apre uno);
- **a destra**, i file della cartella, i grafici, l'aiuto.

Due regole per scrivere nella console:

- le istruzioni vanno scritte esattamente come nelle istruzioni, con le stesse parentesi e le stesse virgolette; maiuscole e minuscole contano;
- R vuole le virgolette dritte (`"`). I programmi di scrittura (Word, Pages, le note del telefono) le trasformano spesso in virgolette curve (“ ”), e con quelle R non funziona. Conviene copiare le istruzioni da questi file `LEGGIMI.md`, non da un documento impaginato.

## Installare i pacchetti (una volta sola)

Un *pacchetto* è un'aggiunta a R che contiene funzioni già pronte. Il principale, per questo tutorial, è quello dell'OMS, `healthequal`. Nella console, dopo il `>`, si scrive:

```r
install.packages("healthequal")
```

e si preme Invio. Compaiono molte righe, a volte in rosso: il rosso non vuol dire per forza un errore, R sta scaricando anche altri pacchetti di cui `healthequal` ha bisogno. Ci vogliono alcuni minuti. Quando torna il `>`, l'installazione è finita.

Altri pacchetti vengono chiesti strada facendo, e RStudio di solito se ne accorge da solo:

- aprendo un programma che usa un pacchetto mancante, RStudio mostra in alto una **barra gialla** («Package readxl required but is not installed»): si fa clic su **Install**;
- eseguendo un programma, `healthequal` può chiedere il pacchetto `sandwich` («Package `sandwich` required to get robust standard errors»): serve a un passaggio tecnico e non cambia i risultati; si accetta l'installazione, oppure si scrive `install.packages("sandwich")`, e si riesegue il programma.

In generale, se compare un messaggio con le parole `there is no package called` seguite da un nome fra virgolette, si installa quel pacchetto con `install.packages("nome")` e si riprova.

## Eseguire un programma

Ogni cartella dei capitoli contiene uno o più programmi `.R`. Per eseguirne uno:

1. in RStudio, menu **File** → **Open File...**;
2. si va nella cartella del capitolo e si sceglie il programma (per esempio `misure.R`): si apre nel riquadro in alto a sinistra, dove lo si può leggere con i suoi commenti;
3. si preme il pulsante **Source**, in alto a destra di quel riquadro;
4. i risultati compaiono nella console, in basso a sinistra. Nel `LEGGIMI.md` di ogni capitolo c'è il risultato che si deve vedere, per controllare.

**Senza RStudio.** Si può usare anche R da solo. Si apre R, si scrive `source(file.choose())` e si preme Invio; nella finestra che si apre si sceglie il programma. Chi usa R dal Terminale del Mac non vede una finestra ma la scritta `Enter file name:`: si trascina il file dal Finder dentro il Terminale e si preme Invio.

## Se qualcosa non va

| Messaggio | Che cosa vuol dire | Che cosa fare |
| --- | --- | --- |
| `there is no package called '...'` | manca un pacchetto | installarlo con `install.packages("...")` |
| `cannot open file` (senza altro) | R non trova il file | riaprire il programma dal menu **File → Open File...** dentro la sua cartella, senza spostarlo, e premere di nuovo **Source** |
| `unexpected input` o `unexpected symbol` | l'istruzione è stata copiata male | controllare le virgolette (devono essere dritte) e le parentesi |
| `cannot open file` ... `Operation not permitted` (sul Mac) | il Mac non dà a RStudio il permesso di leggere quella cartella | vedere sopra, «Un permesso da dare, sul Mac» |
| il `>` non torna e compare un `+` | manca una parentesi o una virgoletta di chiusura | premere **Esc** e riscrivere l'istruzione |

## Licenze

- **Testi e immagini** (questi `LEGGIMI.md` e i grafici `.png`): licenza Creative Commons BY-NC-SA 4.0 (<https://creativecommons.org/licenses/by-nc-sa/4.0/deed.it>), come il libro: si possono copiare e adattare citando l'autore, senza scopo di lucro e condividendo allo stesso modo.
- **Programmi e fogli elettronici** (i file `.R` e `.xlsx`): licenza MIT, nel file `LICENSE-CODE`. Si possono usare, cambiare e ridistribuire liberamente, anche per lavoro, conservando l'indicazione dell'autore.
- **Dati.** Restano delle loro fonti, che li distribuiscono con licenze aperte e chiedono di essere citate:
  - ISTAT (mortalità per titolo di studio, popolazione, decessi comunali, censimento): Creative Commons BY 4.0 (<https://www.istat.it/note-legali/>);
  - Ministero dell'Economia e delle Finanze (redditi IRPEF per comune): Creative Commons BY 3.0 Italia, con la citazione «MEF - Dipartimento delle Finanze» (<https://www1.finanze.gov.it/finanze/pagina_dichiarazioni/public/dichiarazioni.php>);
  - PASSI e PASSI d'Argento (schede dell'Osservatorio epidemiologico dell'azienda sanitaria trentina, pubblicate su EpiCentro dell'Istituto superiore di sanità): Creative Commons BY 4.0, la licenza dei dati e documenti dell'ISS (<https://www.iss.it/contatti>).

  I file della cartella `capitolo-4/dati_originali` sono quelli delle fonti, rinominati ma non modificati. Le altre tabelle `.csv` sono elaborazioni fatte per il libro a partire da quei dati (scelte di righe e colonne, somme, calcoli): si distribuiscono con licenza Creative Commons BY 4.0, citando insieme l'autore e le fonti indicate nel `LEGGIMI.md` di ogni cartella.
