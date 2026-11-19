# =============================================================================
# Lo sappiamo già - Capitolo 4: reddito e mortalità per territorio
# =============================================================================
#
# Che cosa fa: ordina i comuni di una provincia dal più povero al più ricco
# (reddito dichiarato per abitante), li divide in cinque gruppi con circa lo
# stesso numero di abitanti (i quintili) e per ogni gruppo calcola il rapporto
# standardizzato di mortalità (SMR), su tutte le età e sotto i 65 anni.
#
# Usa la tabella comuni_TN.csv, già pronta per il Trentino. Per un'altra
# provincia, la tabella si prepara con prepara_dati.R (vedi LEGGIMI.md).
#
# Come si usa: aprirlo in RStudio (File -> Open File...) e premere il pulsante Source.
# Senza RStudio: in R scrivere  source(file.choose())  e scegliere questo file.
# Non servono pacchetti aggiuntivi.
# =============================================================================


# --- PASSO 1. Quale tabella usare ---------------------------------------------
# Per un'altra provincia si cambia la sigla (deve esistere il file comuni_XX.csv).

SIGLA_PROVINCIA <- "TN"


# --- PASSO 2. Lettura della tabella dei comuni ---------------------------------
cartella <- tryCatch(dirname(normalizePath(sys.frame(1)$ofile)),
                     error = function(e) getwd())
file_comuni <- file.path(cartella, paste0("comuni_", SIGLA_PROVINCIA, ".csv"))
if (!file.exists(file_comuni)) {
  stop(paste0("Non trovo il file ", basename(file_comuni), " accanto a questo programma.\n",
              "Per una provincia nuova bisogna prima eseguire prepara_dati.R."), call. = FALSE)
}
comuni <- read.csv(file_comuni, colClasses = c(codice = "character"))
strati <- c("M_0_64", "M_65_74", "M_75_84", "M_85", "F_0_64", "F_65_74", "F_75_84", "F_85")


# --- PASSO 3. Tassi di mortalità della provincia (il riferimento) --------------
# Per ogni sesso e classe d'età: decessi dei tre anni divisi per (abitanti x 3).

tasso <- sapply(strati, function(s)
  sum(comuni[[paste0("morti_", s)]]) / (3 * sum(comuni[[paste0("pop_", s)]])))


# --- PASSO 4. Decessi osservati e attesi in ogni comune -------------------------
# Attesi = quanti morti ci sarebbero stati con i tassi della provincia.

comuni$osservati <- 0; comuni$attesi <- 0
comuni$osservati_65 <- 0; comuni$attesi_65 <- 0
for (s in strati) {
  oss <- comuni[[paste0("morti_", s)]]
  att <- 3 * comuni[[paste0("pop_", s)]] * tasso[[s]]
  comuni$osservati <- comuni$osservati + oss
  comuni$attesi    <- comuni$attesi + att
  if (grepl("0_64", s)) {
    comuni$osservati_65 <- comuni$osservati_65 + oss
    comuni$attesi_65    <- comuni$attesi_65 + att
  }
}


# --- PASSO 5. Comuni in fila per reddito e divisi in cinque gruppi -------------
comuni$reddito_ab <- comuni$reddito / comuni$abitanti
comuni <- comuni[order(comuni$reddito_ab), ]
cumulata <- cumsum(comuni$abitanti) - comuni$abitanti / 2       # punto medio di ogni comune
comuni$quintile <- pmin(5, floor(5 * cumulata / sum(comuni$abitanti)) + 1)


# --- PASSO 6. SMR per quintile, con intervallo di confidenza al 95% ------------
# Intervallo calcolato con l'approssimazione di Byar, quella usata di solito per l'SMR.

byar <- function(O, E) {
  basso <- O * (1 - 1 / (9 * O) - 1.96 / (3 * sqrt(O)))^3
  alto  <- (O + 1) * (1 - 1 / (9 * (O + 1)) + 1.96 / (3 * sqrt(O + 1)))^3
  100 * c(basso, alto) / E
}

ris <- do.call(rbind, lapply(1:5, function(q) {
  g <- comuni[comuni$quintile == q, ]
  O <- sum(g$osservati); E <- sum(g$attesi)
  O65 <- sum(g$osservati_65); E65 <- sum(g$attesi_65)
  data.frame(quintile = q, comuni = nrow(g), abitanti = sum(g$abitanti),
             reddito_ab = sum(g$reddito) / sum(g$abitanti),
             SMR = 100 * O / E, SMR_basso = byar(O, E)[1], SMR_alto = byar(O, E)[2],
             SMR65 = 100 * O65 / E65, SMR65_basso = byar(O65, E65)[1], SMR65_alto = byar(O65, E65)[2])
}))


# --- PASSO 7. Indice di pendenza --------------------------------------------------
# Come nel capitolo 2: ogni quintile nel suo punto medio sulla scala da 0 a 1,
# pesato con la sua quota di abitanti.

pendenza <- function(valori, pesi) {
  p <- pesi / sum(pesi)
  rango <- cumsum(p) - p / 2
  media <- sum(p * valori)
  sum(p * (rango - 0.5) * (valori - media)) / sum(p * (rango - 0.5)^2)
}
# La mortalità è un indicatore sfavorevole: come in HEAT si rovescia il segno, così un
# valore positivo vuol dire che si muore di più nei comuni più poveri.
pend    <- -pendenza(ris$SMR, ris$abitanti)
pend_65 <- -pendenza(ris$SMR65, ris$abitanti)


# --- PASSO 8. Stampa e salvataggio dei risultati -------------------------------
stampa <- function(testo) cat(gsub("([0-9])\\.([0-9])", "\\1,\\2", testo))

cat("\n")
cat("RISULTATI: mortalità 2022-2024 per quintile di reddito dei comuni,", SIGLA_PROVINCIA, "\n")
cat("(SMR: 100 = mortalità uguale alla media della provincia, a parità di età e sesso)\n\n")
cat("Quintile  Comuni  Abitanti  Reddito/ab.   SMR  (int. conf.)    SMR <65  (int. conf.)\n")
for (i in 1:5) {
  r <- ris[i, ]
  stampa(sprintf("%5d %8d %9d %10.0f € %6.1f  (%5.1f-%5.1f)  %7.1f  (%5.1f-%5.1f)\n",
                 r$quintile, r$comuni, r$abitanti, r$reddito_ab,
                 r$SMR, r$SMR_basso, r$SMR_alto, r$SMR65, r$SMR65_basso, r$SMR65_alto))
}
cat("\n")
stampa(sprintf("Indice di pendenza, tutte le età:   %5.1f punti di SMR (positivo: si muore di più nei comuni più poveri)\n", pend))
stampa(sprintf("Indice di pendenza, sotto i 65 anni: %5.1f punti\n", pend_65))
cat("\nIl quintile 1 è il più povero. Se gli intervalli di confidenza si sovrappongono,\n")
cat("le differenze fra quintili potrebbero essere dovute al caso.\n")

# Il file dei risultati è fatto per essere letto con il foglio elettronico:
# intestazioni per esteso, numeri arrotondati (reddito all'euro, SMR a un
# decimale), punto e virgola fra le colonne e virgola decimale, come si aspettano
# Excel, Numbers e LibreOffice in italiano.
tabella <- data.frame(
  "Quintile (1 = più povero)"            = ris$quintile,
  "Comuni"                               = ris$comuni,
  "Abitanti"                             = ris$abitanti,
  "Reddito per abitante (euro)"          = round(ris$reddito_ab),
  "SMR tutte le età"                     = round(ris$SMR, 1),
  "SMR tutte le età, intervallo da"      = round(ris$SMR_basso, 1),
  "SMR tutte le età, intervallo a"       = round(ris$SMR_alto, 1),
  "SMR sotto i 65 anni"                  = round(ris$SMR65, 1),
  "SMR sotto i 65 anni, intervallo da"   = round(ris$SMR65_basso, 1),
  "SMR sotto i 65 anni, intervallo a"    = round(ris$SMR65_alto, 1),
  check.names = FALSE)
uscita <- file.path(cartella, paste0("risultati_quintili_", SIGLA_PROVINCIA, ".csv"))
write.csv2(tabella, uscita, row.names = FALSE, fileEncoding = "UTF-8")
cat("\nI risultati sono stati salvati anche nel file", basename(uscita),
    "(si apre con il foglio elettronico).\n\n")
