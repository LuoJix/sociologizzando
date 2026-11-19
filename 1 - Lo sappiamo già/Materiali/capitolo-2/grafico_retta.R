# =============================================================================
# Lo sappiamo già - Capitolo 2: il grafico della retta
# =============================================================================
#
# Che cosa fa: disegna il grafico dell'indice di pendenza del capitolo 2 e lo
# salva come immagine nella stessa cartella di questo programma, a colori
# (retta_pendenza.png) e in bianco e nero per la stampa (retta_pendenza_bn.png);
# in RStudio i file compaiono anche nel riquadro a destra.
#
# Sul piano cartesiano:
#   - in orizzontale, la posizione nella scala dell'istruzione, da 0 (il meno
#     istruito) a 1 (il più istruito); ogni gruppo occupa un tratto lungo
#     quanto la sua quota di popolazione;
#   - in verticale, la percentuale di sedentari;
#   - ogni gruppo è un punto, a metà del suo tratto; il punto è più grande se
#     il gruppo è più numeroso;
#   - la retta è quella che passa più vicino ai tre punti, tenendo conto del
#     peso di ciascuno. La distanza fra i suoi due capi è l'indice di pendenza.
#
# Come si usa: aprirlo in RStudio (File -> Open File...) e premere Source.
# Senza RStudio: in R scrivere  source(file.choose())  e scegliere questo file.
# Non servono pacchetti aggiuntivi.
#
# Per usarlo con i propri dati: cambiare i numeri nelle tre righe qui sotto,
# sempre dal gruppo più svantaggiato al più favorito.
# =============================================================================

gruppi <- c("Fino alla\nlicenza media", "Diploma", "Laurea")
popolazione <- c(61361, 148766, 76964)  # residenti di 25-64 anni (censimento ISTAT 2024)
quota  <- popolazione / sum(popolazione)  # quote di popolazione (la somma fa 1)
valore <- c(20, 13, 9)             # percentuale di sedentari

cartella <- tryCatch(dirname(normalizePath(sys.frame(1)$ofile)), error = function(e) getwd())

# Il rango: la metà del tratto occupato da ciascun gruppo
fine  <- cumsum(quota)
inizio <- fine - quota
rango <- inizio + quota / 2

# La retta che passa più vicino ai punti, con il peso di ciascun gruppo
retta <- lm(valore ~ rango, weights = quota)
capo0 <- unname(coef(retta)[1])                 # dove la retta tocca lo 0
capo1 <- unname(coef(retta)[1] + coef(retta)[2]) # dove la retta tocca l'1
indice <- capo0 - capo1

virgola <- function(x) format(round(x, 1), nsmall = 1, decimal.mark = ",")

blu  <- c("#0d366b", "#3987e5", "#86b6ef")
ink  <- "#0b0b0b"; ink2 <- "#52514e"; griglia <- "#e4e3df"; fondo <- "#fcfcfb"
fasce <- c("#eef3fb", "#f6f8fc", "#eef3fb")

# Il grafico si disegna due volte: a colori (retta_pendenza.png, per lo schermo)
# e in grigi con i caratteri più grandi (retta_pendenza_bn.png, per la stampa in
# bianco e nero). Nel libro la figura è larga circa 12 cm: a parità di pixel in
# larghezza, la risoluzione più alta (res = 280) la rende più stretta in
# centimetri, e quando la pagina la allarga si ingrandiscono anche le scritte.
# testo: quanto ingrandire le scritte non in neretto (nomi dei gruppi, assi,
# sottotitolo, fonte); 1 lascia le misure di base.
disegna <- function(file, punti, fasce, accento, titolo, sottotitolo, bordo = fondo, res = 200, testo = 1, testo_fonte = testo) {
  png(file.path(cartella, file), width = 1600, height = round(1150 * res / 200), res = res, bg = fondo)
  # titolo e sottotitolo possono andare su più righe: il margine in alto cresce con loro
  par(mar = c(5.2, 4.2, 4.2 + 1.2 * (length(titolo) + length(sottotitolo) - 2), 1.2),
      family = "sans", col.axis = ink2, fg = ink2)
  plot(NA, xlim = c(0, 1), ylim = c(0, 28), axes = FALSE, xlab = "", ylab = "", xaxs = "i", yaxs = "i")

  # I tratti dei tre gruppi
  for (i in 1:3) rect(inizio[i], 0, fine[i], 28, col = fasce[i], border = NA)
  abline(h = seq(0, 25, 5), col = griglia, lwd = 1)
  abline(v = fine[1:2], col = "#c9cfd9", lty = 3)
  text(rango, 27.4, gruppi, cex = 0.72 * testo, col = ink2, adj = c(0.5, 1))
  axis(1, at = c(0, fine[1:2], 1), labels = c("0", format(round(fine[1:2], 3), decimal.mark = ","), "1"),
       cex.axis = 0.75 * testo, tick = FALSE, line = -0.5)
  axis(2, at = seq(0, 25, 5), las = 1, tick = FALSE, cex.axis = 0.75 * testo, line = -0.6)
  mtext("Posizione nella scala dell'istruzione (0 = il meno istruito, 1 = il più istruito)",
        side = 1, line = 2.2, cex = 0.78 * testo, col = ink2)
  mtext("Sedentari (%)", side = 2, line = 2.4, cex = 0.78 * testo, col = ink2)

  # La retta, da un capo all'altro della scala
  segments(0, capo0, 1, capo1, col = ink, lwd = 2.2)

  # I tre punti, grandi quanto il gruppo
  points(rango, valore, pch = 21, bg = punti, col = bordo, cex = 2 + 6 * sqrt(quota), lwd = 1.5)
  for (i in 1:3) text(rango[i], valore[i], paste0(valore[i], "%"), pos = 1, offset = 1 + 2.2 * sqrt(quota[i]), cex = 0.78, col = ink, font = 2)

  # I due capi e la loro distanza
  points(c(0, 1), c(capo0, capo1), pch = 19, cex = 0.9, col = ink)
  text(0.012, capo0 + 1.4, virgola(capo0), adj = c(0, 0.5), cex = 0.78, col = ink, font = 2)
  text(0.988, capo1 - 1.4, virgola(capo1), adj = c(1, 0.5), cex = 0.78, col = ink, font = 2)
  arrows(0.955, capo1, 0.955, capo0, code = 3, length = 0.07, col = accento, lwd = 1.4)
  segments(0, capo0, 0.955, capo0, col = accento, lty = 2, lwd = 1)
  text(0.94, (capo0 + capo1) / 2, paste0("indice di pendenza\n", virgola(indice), " punti"),
       adj = c(1, 0.5), cex = 0.78, col = accento, font = 2)

  ns <- length(sottotitolo); nt <- length(titolo)
  for (k in seq_len(ns)) mtext(sottotitolo[k], side = 3, line = 0.9 + 1.0 * (ns - k), adj = 0, cex = 0.68 * testo, col = ink2)
  for (k in seq_len(nt)) mtext(titolo[k], side = 3, line = 2.2 + 1.0 * (ns - 1) + 1.25 * (nt - k),
                               adj = 0, cex = 0.95, font = 2, col = ink)
  mtext("Fonti: PASSI 2023-2024 (sedentari, 18-64 anni); censimento permanente ISTAT 2024 (quote, 25-64 anni)",
        side = 1, line = 3.9, adj = 0, cex = 0.6 * testo_fonte, col = ink2)
  dev.off()
}

disegna("retta_pendenza.png", punti = blu, fasce = fasce, accento = "#b3261e",
        titolo = "Trentino: sedentari per titolo di studio e retta dell'indice di pendenza",
        sottotitolo = c("Ogni gruppo occupa un tratto lungo quanto la sua quota di popolazione;",
                        "il punto sta a metà del tratto."), testo = 1.25)
# nella versione per la stampa titolo e sottotitolo vanno su due righe ciascuno:
# con i caratteri più grandi su una riga sola non ci stanno
disegna("retta_pendenza_bn.png", punti = c("#1a1a1a", "#6e6e6e", "#c4c4c4"),
        fasce = c("#ececec", "#f7f7f7", "#ececec"), accento = "#3a3a3a", bordo = "#1a1a1a", res = 280, testo = 1.15, testo_fonte = 1,
        titolo = c("Trentino: sedentari per titolo di studio", "e retta dell'indice di pendenza"),
        sottotitolo = c("Ogni gruppo occupa un tratto lungo quanto la sua quota di popolazione;",
                        "il punto sta a metà del tratto."))

cat("\nIndice di pendenza:", virgola(indice), "punti",
    "\n(la retta vale", virgola(capo0), "a sinistra e", virgola(capo1), "a destra)",
    "\nIl grafico è nel file retta_pendenza.png, nella cartella di questo programma;",
    "\nla versione per la stampa in bianco e nero è retta_pendenza_bn.png.\n\n")
