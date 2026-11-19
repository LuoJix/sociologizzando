# =============================================================================
# Lo sappiamo già - Capitolo 6: i grafici a punti (equiplot)
# =============================================================================
#
# Che cosa fa: disegna i due grafici a punti del capitolo 6 e li salva come
# immagini (file .png), a colori e in bianco e nero, nella stessa cartella di
# questo programma; in RStudio
# compaiono anche nel riquadro dei file, a destra.
#
# Come si usa: aprirlo in RStudio (File -> Open File...) e premere Source.
# Senza RStudio: in R scrivere  source(file.choose())  e scegliere questo file.
# Non servono pacchetti aggiuntivi.
#
# Per disegnare un grafico con i propri dati: copiare uno dei due blocchi in
# fondo (GRAFICO 1 o GRAFICO 2) e cambiare nomi, valori, titolo e nome del file.
# =============================================================================

cartella <- tryCatch(dirname(normalizePath(sys.frame(1)$ofile)), error = function(e) getwd())

# Colori: un solo blu, dal più scuro (gruppo più svantaggiato) al più chiaro.
# Per la stampa in bianco e nero c'è una seconda serie, in grigi.
# Forme: ogni gruppo ha anche una forma sua (cerchio, triangolo, quadrato, rombo),
# così il grafico si legge anche quando le tonalità si confondono.
blu   <- c("#0d366b", "#1c5cab", "#3987e5", "#86b6ef")   # dal gruppo più svantaggiato al più favorito
grigi <- c("#1a1a1a", "#555555", "#999999", "#dddddd")
forme <- c(21, 24, 22, 23)                                 # cerchio, triangolo, quadrato, rombo
ink  <- "#0b0b0b"; ink2 <- "#52514e"; griglia <- "#e4e3df"; fondo <- "#fcfcfb"

equiplot <- function(file, righe, valori, gruppi, colori, forme, xlim, xlab, titolo, nota, bordo = fondo, res = 200, testo = 1) {
  # l'altezza in centimetri resta quella della risoluzione 200: cambia solo la larghezza;
  # cresce con le scritte (testo), perché titolo, legenda e assi prendono più spazio
  png(file.path(cartella, file), width = 1600, height = round((440 * testo + 150 * length(righe)) * res / 200),
      res = res, bg = fondo)
  # margine sinistro: quanto basta al nome di riga più lungo
  sinistro <- 1.5 + 0.48 * testo * max(nchar(righe))
  par(oma = c(1.9 * testo, 0.6, 4.8 * testo, 0.6), mar = c(3.4 * testo, sinistro, 0.6, 1.5), family = "sans", col.axis = ink2, fg = ink2)
  n <- length(righe)
  plot(NA, xlim = xlim, ylim = c(0.5, n + 0.5), axes = FALSE, xlab = "", ylab = "")
  abline(v = pretty(xlim), col = griglia, lwd = 1)
  axis(1, at = pretty(xlim), tick = FALSE, cex.axis = 0.8 * testo, line = -0.6)
  mtext(xlab, side = 1, line = 2 * testo, cex = 0.8 * testo, col = ink2)
  axis(2, at = n:1, labels = righe, las = 1, tick = FALSE, cex.axis = 0.85 * testo, col.axis = ink)
  for (i in seq_len(n)) {
    v <- valori[i, ]; y <- n - i + 1
    segments(min(v, na.rm = TRUE), y, max(v, na.rm = TRUE), y, col = "#b9b8b2", lwd = 2)
    points(v, rep(y, length(v)), pch = forme, bg = colori, col = bordo, cex = 2.1, lwd = 1.5)
  }
  mtext(titolo, side = 3, outer = TRUE, line = 4.8 * testo - 1.6, adj = 0, cex = 0.95, font = 2, col = ink)
  par(fig = c(0, 1, 0, 1), oma = c(0, 0, 0, 0), mar = c(0, 0, 0, 0), new = TRUE)
  plot(NA, xlim = c(0, 1), ylim = c(0, 1), axes = FALSE, xlab = "", ylab = "")
  legend(0.0, 1 - 2.9 * testo * par("csi") / par("din")[2], horiz = TRUE, bty = "n", legend = gruppi,
         pch = forme, pt.bg = colori, col = bordo, pt.cex = 1.6 * testo, cex = 0.75 * testo, text.col = ink2,
         text.width = strwidth(gruppi, cex = 0.75 * testo) * 1.1, x.intersp = 1.2, yjust = 0.5)
  text(0.005, 0.03, nota, adj = c(0, 0), cex = 0.62 * testo, col = ink2)
  dev.off()
}

# Ogni grafico si disegna due volte: a colori (per lo schermo) e in grigi, con
# il nome che finisce in "_bn" (per la stampa in bianco e nero).
# La versione per la stampa ha anche i caratteri più grandi: nel libro la figura
# è larga circa 12 cm, e a risoluzione 200 le scritte uscivano di 4-6 punti.
# A parità di pixel in larghezza, una risoluzione più alta (res = 280) rende il
# disegno più stretto in centimetri, e quando la pagina lo allarga si ingrandisce
# tutto, scritte comprese; l'altezza in centimetri resta la stessa, perché le
# righe e la legenda non si schiaccino.
# testo: quanto ingrandire legenda, nomi delle righe, assi e fonte rispetto al
# disegno di partenza (1,25 a colori, 1,15 in grigi, dove la risoluzione più
# alta le ha già ingrandite).
disegna <- function(file, gruppi, quali, ...) {
  equiplot(paste0(file, ".png"), gruppi = gruppi, colori = blu[quali], forme = forme[quali], testo = 1.25, ...)
  equiplot(paste0(file, "_bn.png"), gruppi = gruppi, colori = grigi[quali], forme = forme[quali],
           bordo = "#1a1a1a", res = 280, testo = 1.15, ...)
}

# --- GRAFICO 1. Tre indicatori PASSI per titolo di studio, Trentino ----------
# Ogni riga di rbind() è un indicatore; i numeri vanno dal gruppo più svantaggiato al più favorito.
# Con tre gruppi si usano il primo, il terzo e il quarto colore e forma (quali = c(1, 3, 4)).
passi <- rbind(c(20, 13, 9), c(18, 8, 7), c(11, 10, 9))
disegna("equiplot_passi_istruzione",
        gruppi = c("Fino alla licenza media", "Diploma", "Laurea"), quali = c(1, 3, 4),
        righe = c("Adulti 18-64 sedentari", "Adulti 18-69 con obesità", "Anziani 70+ con obesità"),
        valori = passi, xlim = c(0, 25), xlab = "per cento",
        titolo = "Trentino: stili di vita per titolo di studio",
        nota = "Fonte: Osservatorio epidemiologico APSS-ASUIT, PASSI e PASSI d'Argento 2023-2025")

# --- GRAFICO 2. Mortalità 30-69 anni per titolo di studio, Trentino e Italia, 2022 ---
mort <- rbind(c(30.9, 29.2, 21.1, 14.6), c(44.3, 34.8, 25.5, 19.0))
disegna("equiplot_mortalita_trentino_italia",
        gruppi = c("Nessuno o elementare", "Licenza media", "Diploma", "Laurea"), quali = 1:4,
        righe = c("Trentino", "Italia"), valori = mort,
        xlim = c(0, 50), xlab = "morti ogni 10.000 abitanti, tasso standardizzato",
        titolo = "Mortalità fra i 30 e i 69 anni per titolo di studio, 2022",
        nota = "Fonte: ISTAT, indicatori di mortalità per causa e titolo di studio")

cat("\nFatto: i due grafici sono stati salvati nella cartella del programma,\n")
cat("ciascuno a colori e in bianco e nero (il nome finisce in _bn):\n")
cat("  equiplot_passi_istruzione.png, equiplot_passi_istruzione_bn.png\n")
cat("  equiplot_mortalita_trentino_italia.png, equiplot_mortalita_trentino_italia_bn.png\n\n")
