# =============================================================================
# Lo sappiamo già - Capitolo 4: preparare i dati dei comuni
# =============================================================================
#
# Che cosa fa: dai file nazionali del Ministero dell'Economia e dell'ISTAT
# costruisce una tabella con una riga per ogni comune di una provincia:
# abitanti per sesso ed età, decessi 2022-2024 per sesso ed età, reddito
# dichiarato. La tabella serve al programma quintili.R.
#
# Serve SOLO a chi vuole rifare i conti su un'altra provincia: per il Trentino
# la tabella è già pronta (comuni_TN.csv) e si può passare a quintili.R.
#
# Prima di usarlo (istruzioni complete nel file LEGGIMI.md):
#   - installare una volta il pacchetto readxl:  install.packages("readxl")
#   - mettere i file scaricati nella cartella dati_originali, accanto a questo file
#   - cambiare le due righe del PASSO 1
#
# Come si usa: aprirlo in RStudio (File -> Open File...) e premere il pulsante Source.
# Senza RStudio: in R scrivere  source(file.choose())  e scegliere questo file.
# =============================================================================


# --- PASSO 1. La provincia (cambiare queste due righe) -------------------------
# Il codice ISTAT della provincia ha tre cifre: è il numero che compare nel nome
# del file della popolazione (POSAS_2023_it_022_Trento.csv -> "022";
# POSAS_2023_it_037_Bologna.csv -> "037"). La sigla è quella delle targhe.

CODICE_PROVINCIA <- "022"
SIGLA_PROVINCIA  <- "TN"


# --- Da qui in poi non serve cambiare niente -----------------------------------

if (!requireNamespace("readxl", quietly = TRUE)) {
  stop("Manca il pacchetto readxl. Scrivere  install.packages(\"readxl\")  e riprovare.",
       call. = FALSE)
}

# La cartella in cui si trova questo programma
cartella <- tryCatch(dirname(normalizePath(sys.frame(1)$ofile)),
                     error = function(e) getwd())
originali <- file.path(cartella, "dati_originali")

trova <- function(modello, descrizione) {
  f <- list.files(originali, pattern = modello, full.names = TRUE, ignore.case = TRUE)
  if (length(f) == 0) {
    stop(paste0("Non trovo ", descrizione, " nella cartella dati_originali.\n",
                "Controllare di averlo scaricato e messo lì (vedi LEGGIMI.md)."), call. = FALSE)
  }
  f[1]
}

classi <- c("0_64", "65_74", "75_84", "85")


# --- PASSO 2. Popolazione per comune, sesso ed età (ISTAT) ---------------------
cat("Leggo la popolazione...\n")
f_pop <- trova(paste0("^POSAS_2023_it_", CODICE_PROVINCIA, ".*\\.csv$"),
               paste0("il file della popolazione (POSAS_2023_it_", CODICE_PROVINCIA, "_...csv)"))
pop <- read.csv(f_pop, sep = ";", skip = 1, check.names = FALSE,
                colClasses = c("Codice comune" = "character"), fileEncoding = "UTF-8")
pop <- pop[pop[["Età"]] != 999, ]
pop$classe <- cut(pop[["Età"]], breaks = c(-1, 64, 74, 84, Inf), labels = classi)

comuni <- unique(pop[, c("Codice comune", "Comune")])
names(comuni) <- c("codice", "comune")
for (cl in classi) {
  sel <- pop[pop$classe == cl, ]
  m <- tapply(sel[["Totale maschi"]], sel[["Codice comune"]], sum)
  f <- tapply(sel[["Totale femmine"]], sel[["Codice comune"]], sum)
  comuni[[paste0("pop_M_", cl)]] <- as.numeric(m[comuni$codice])
  comuni[[paste0("pop_F_", cl)]] <- as.numeric(f[comuni$codice])
}
comuni$abitanti <- rowSums(comuni[, grep("^pop_", names(comuni))])


# --- PASSO 3. Decessi 2022-2024 per comune, sesso ed età (ISTAT) ---------------
for (cl in classi) {
  comuni[[paste0("morti_M_", cl)]] <- 0
  comuni[[paste0("morti_F_", cl)]] <- 0
}
for (anno in 2022:2024) {
  cat("Leggo i decessi del", anno, "...\n")
  # va bene sia il nome originale dell'ISTAT («tavola riepilogativa_decessi comunali
  # per mese, sesso e classe di età_2022.xlsx») sia un nome abbreviato che finisca con _2022.xlsx
  f_dec <- trova(paste0("decessi.*_", anno, "\\.xlsx$"),
                 paste0("il file dei decessi del ", anno))
  d <- suppressMessages(readxl::read_excel(f_dec, skip = 3, col_names = FALSE, col_types = "text"))
  d <- d[!is.na(d[[2]]) & d[[2]] == CODICE_PROVINCIA, ]
  num <- function(col) { x <- suppressWarnings(as.numeric(d[[col]])); x[is.na(x)] <- 0; x }
  # Dopo le prime 6 colonne, ogni mese ha 8 colonne: totale M, F; 65-74 M, F; 75-84 M, F; 85+ M, F
  for (mese in 0:11) {
    b <- 6 + mese * 8
    for (s in 0:1) {
      sesso <- c("M", "F")[s + 1]
      tot <- num(b + 1 + s); e65 <- num(b + 3 + s); e75 <- num(b + 5 + s); e85 <- num(b + 7 + s)
      valori <- list("0_64" = tot - e65 - e75 - e85, "65_74" = e65, "75_84" = e75, "85" = e85)
      for (cl in classi) {
        somma <- tapply(valori[[cl]], d[[6]], sum)
        col <- paste0("morti_", sesso, "_", cl)
        agg <- as.numeric(somma[comuni$codice]); agg[is.na(agg)] <- 0
        comuni[[col]] <- comuni[[col]] + agg
      }
    }
  }
}


# --- PASSO 4. Reddito dichiarato per comune (Ministero dell'Economia) ----------
cat("Leggo i redditi...\n")
f_mef <- trova("comunale_CSV_2024\\.csv$", "il file dei redditi (..._comunale_CSV_2024.csv)")
mef <- read.csv(f_mef, sep = ";", check.names = FALSE, colClasses = "character",
                fileEncoding = "latin1")
mef <- mef[mef[["Sigla Provincia"]] == SIGLA_PROVINCIA, ]
reddito <- as.numeric(mef[["Reddito complessivo - Ammontare in euro"]])
names(reddito) <- mef[["Codice Istat Comune"]]
comuni$reddito <- as.numeric(reddito[comuni$codice])

mancanti <- comuni$comune[is.na(comuni$reddito)]
if (length(mancanti) > 0) {
  stop(paste("Questi comuni non hanno il reddito nel file del Ministero:",
             paste(mancanti, collapse = ", ")), call. = FALSE)
}


# --- PASSO 5. Salvataggio ------------------------------------------------------
uscita <- file.path(cartella, paste0("comuni_", SIGLA_PROVINCIA, ".csv"))
write.csv(comuni, uscita, row.names = FALSE, fileEncoding = "UTF-8")
cat("\nFatto. Comuni:", nrow(comuni), "- abitanti:", sum(comuni$abitanti),
    "- decessi 2022-2024:", sum(comuni[, grep("^morti_", names(comuni))]), "\n")
cat("La tabella è stata salvata nel file", basename(uscita), "\n")
cat("Ora si può eseguire quintili.R.\n\n")
