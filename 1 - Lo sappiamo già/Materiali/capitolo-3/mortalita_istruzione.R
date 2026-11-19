# =============================================================================
# Lo sappiamo già - Capitolo 3: la mortalità per titolo di studio
# =============================================================================
#
# Che cosa fa: scarica dalla banca dati dell'ISTAT i tassi di mortalità per
# titolo di studio di una regione (o provincia autonoma) e dell'Italia,
# anni 2019-2022, e li stampa in una tabella con il numero di morti di ogni
# gruppo e il rapporto fra chi ha studiato di meno e chi ha studiato di più.
#
# Serve il collegamento a internet. Non servono pacchetti aggiuntivi.
#
# Come si usa: aprirlo in RStudio (File -> Open File...) e premere Source.
# Senza RStudio: in R scrivere  source(file.choose())  e scegliere questo file.
# =============================================================================


# --- PASSO 1. Che cosa scaricare (si possono cambiare queste righe) -----------

# Il territorio: il codice va preso dall'elenco nel file LEGGIMI.md
# (per esempio "ITC1" Piemonte, "ITD3" Veneto, "ITE4" Lazio, "ITG1" Sicilia).
TERRITORIO <- "ITD2"      # Provincia autonoma di Trento

# Il sesso: "T" maschi e femmine insieme, "M" maschi, "F" femmine.
SESSO <- "T"

# L'età: "Y30-69" (da 30 a 69 anni), "Y70-84", "Y_GE85" (85 e oltre), "Y_GE30" (30 e oltre).
ETA <- "Y30-69"


# --- PASSO 2. Scaricamento dalla banca dati dell'ISTAT -------------------------
# La tavola è «Indicatori di mortalità per causa e titolo di studio»
# (esploradati.istat.it). La causa "99" vuol dire tutte le cause.

indirizzo <- paste0("https://esploradati.istat.it/SDMXWS/rest/data/",
                    "IT1,39_1_DF_DCIS_IND_MORT_EDU_1,1.0/",
                    "A.", TERRITORIO, "+IT.STMRATE+DEATH.", SESSO, ".", ETA, "..99")

cat("Scarico i dati dall'ISTAT (ci vuole qualche secondo)...\n")
options(timeout = 300)
dati <- tryCatch(
  # colClasses = "character": tutto come testo, altrimenti R legge la sigla "T" come TRUE
  read.csv(url(indirizzo, headers = c(Accept = "application/vnd.sdmx.data+csv;version=1.0.0")),
           colClasses = "character"),
  error = function(e) NULL)
if (is.null(dati) || nrow(dati) == 0) {
  stop(paste("L'ISTAT non ha risposto, oppure non ci sono dati per questa scelta.",
             "Controllare il collegamento a internet e i codici del PASSO 1, e riprovare."),
       call. = FALSE)
}


# --- PASSO 3. Preparazione della tabella ---------------------------------------
dati$OBS_VALUE <- as.numeric(dati$OBS_VALUE)
gruppi <- c(NP = "Nessuno o elementare", LSE = "Licenza media",
            USE_IF = "Diploma", BL_ML_RDD = "Laurea", ALL = "Tutti")
anni <- sort(unique(dati$TIME_PERIOD))

valore <- function(area, tipo, gruppo, anno) {
  v <- dati$OBS_VALUE[dati$REF_AREA == area & dati$DATA_TYPE == tipo &
                      dati$EDU_LEV_HIGHEST == gruppo & dati$TIME_PERIOD == anno]
  if (length(v) == 0) NA else v
}


# --- PASSO 4. Stampa --------------------------------------------------------------
territori <- c(ITC1 = "Piemonte", ITC2 = "Valle d'Aosta", ITC3 = "Liguria", ITC4 = "Lombardia",
               ITD1 = "Provincia autonoma di Bolzano", ITD2 = "Provincia autonoma di Trento",
               ITD3 = "Veneto", ITD4 = "Friuli-Venezia Giulia", ITD5 = "Emilia-Romagna",
               ITE1 = "Toscana", ITE2 = "Umbria", ITE3 = "Marche", ITE4 = "Lazio",
               ITF1 = "Abruzzo", ITF2 = "Molise", ITF3 = "Campania", ITF4 = "Puglia",
               ITF5 = "Basilicata", ITF6 = "Calabria", ITG1 = "Sicilia", ITG2 = "Sardegna",
               ITC = "Nord-ovest", ITD = "Nord-est", ITE = "Centro", ITF = "Sud", ITG = "Isole")
stampa <- function(testo) cat(gsub("([0-9])\\.([0-9])", "\\1,\\2", testo))

for (area in c(TERRITORIO, "IT")) {
  nome <- if (area == "IT") "Italia" else if (area %in% names(territori)) territori[[area]] else area
  cat("\n")
  cat("MORTALITÀ PER TITOLO DI STUDIO -", nome, "- sesso", SESSO, "- età", ETA, "\n")
  cat("Tasso standardizzato ogni 10.000 abitanti (fra parentesi: numero di morti)\n\n")
  cat(sprintf("%-22s", "Titolo di studio"))
  for (a in anni) cat(sprintf("%17s", a))
  cat(sprintf("%12s\n", "Media"))
  for (g in names(gruppi)) {
    cat(sprintf("%-22s", gruppi[[g]]))
    tassi <- sapply(anni, function(a) valore(area, "STMRATE", g, a))
    for (k in seq_along(anni)) {
      stampa(sprintf("%8.1f (%6.0f)", tassi[k], valore(area, "DEATH", g, anni[k])))
    }
    stampa(sprintf("%12.1f\n", mean(tassi)))
  }
  primo  <- mean(sapply(anni, function(a) valore(area, "STMRATE", "NP", a)))
  ultimo <- mean(sapply(anni, function(a) valore(area, "STMRATE", "BL_ML_RDD", a)))
  stampa(sprintf("\nRapporto fra il primo e l'ultimo gruppo (media degli anni): %.1f volte\n", primo / ultimo))
}

cat("\nAttenzione ai numeri piccoli: se in un gruppo i morti sono poche decine,\n")
cat("il tasso cambia molto da un anno all'altro. Conviene guardare la media.\n")


# --- PASSO 5. Salvataggio -----------------------------------------------------------
cartella <- tryCatch(dirname(normalizePath(sys.frame(1)$ofile)), error = function(e) getwd())
uscita <- file.path(cartella, paste0("mortalita_istruzione_", TERRITORIO, "_", SESSO, "_", ETA, ".csv"))
# Il file è fatto per essere letto con il foglio elettronico: una riga per
# territorio, titolo di studio e anno; intestazioni e voci per esteso al posto
# dei codici dell'ISTAT; il tasso a un decimale; punto e virgola fra le colonne
# e virgola decimale, come si aspettano Excel, Numbers e LibreOffice in italiano.
nomi_sesso <- c(T = "maschi e femmine", M = "maschi", F = "femmine")
nomi_eta   <- c("Y30-69" = "30-69 anni", "Y70-84" = "70-84 anni",
                "Y_GE85" = "85 anni e oltre", "Y_GE30" = "30 anni e oltre")
righe <- list()
for (area in c(TERRITORIO, "IT")) {
  nome <- if (area == "IT") "Italia" else if (area %in% names(territori)) territori[[area]] else area
  for (g in names(gruppi)) for (a in anni) {
    righe[[length(righe) + 1]] <- data.frame(
      "Territorio"                                = nome,
      "Sesso"                                     = unname(nomi_sesso[SESSO]),
      "Età"                                       = unname(nomi_eta[ETA]),
      "Titolo di studio"                          = gruppi[[g]],
      "Anno"                                      = as.integer(a),
      "Tasso standardizzato ogni 10.000 abitanti" = round(valore(area, "STMRATE", g, a), 1),
      "Numero di morti"                           = valore(area, "DEATH", g, a),
      check.names = FALSE)
  }
}
write.csv2(do.call(rbind, righe), uscita, row.names = FALSE, fileEncoding = "UTF-8")
cat("\nI dati scaricati sono stati salvati nel file", basename(uscita), "\n\n")
