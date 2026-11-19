# =============================================================================
# Lo sappiamo già - Capitolo 5: stili di vita per gruppo sociale
# =============================================================================
#
# Che cosa fa: legge il file passi_trentino_heat.csv, scritto nel formato del
# programma HEAT Plus dell'OMS (una riga per gruppo), e per ogni indicatore e
# ogni dimensione (titolo di studio, difficoltà economiche) calcola le misure
# di disuguaglianza che i dati permettono.
#
# Come si usa: aprirlo in RStudio (File -> Open File...) e premere Source.
# Senza RStudio: in R scrivere  source(file.choose())  e scegliere questo file.
#
# Usa il pacchetto healthequal dell'OMS, se è installato, per l'indice di
# pendenza e l'indice relativo; altrimenti calcola l'indice di pendenza a mano
# (versione lineare, come nel foglio elettronico del capitolo 2).
# =============================================================================


# --- PASSO 1. Lettura del file -------------------------------------------------
cartella <- tryCatch(dirname(normalizePath(sys.frame(1)$ofile)), error = function(e) getwd())
# colClasses = "character": tutto come testo (altrimenti R potrebbe leggere male
# alcune sigle); i numeri si convertono subito dopo.
file_dati <- file.path(cartella, "passi_trentino_heat.csv")
# Excel e Numbers in italiano salvano i CSV con il punto e virgola e la virgola
# decimale: il programma riconosce da solo i due formati.
prima_riga <- readLines(file_dati, n = 1, encoding = "UTF-8")
separatore <- if (grepl(";", prima_riga)) ";" else ","
dati <- read.csv(file_dati, sep = separatore, colClasses = "character", encoding = "UTF-8")
for (col in c("estimate", "population", "favourable_indicator", "ordered_dimension",
              "subgroup_order", "reference_subgroup")) {
  x <- gsub(" ", "", dati[[col]])
  if (separatore == ";") x <- gsub(",", ".", gsub("\\.", "", x))   # 61.361 -> 61361; 12,5 -> 12.5
  dati[[col]] <- suppressWarnings(as.numeric(x))
}
oms <- requireNamespace("healthequal", quietly = TRUE)


# --- PASSO 2. Le formule -----------------------------------------------------------
pendenza_a_mano <- function(valori, pop) {
  quota <- pop / sum(pop)
  rango <- cumsum(quota) - quota / 2
  media <- sum(quota * valori)
  sum(quota * (rango - 0.5) * (valori - media)) / sum(quota * (rango - 0.5)^2)
}

stampa <- function(testo) cat(gsub("([0-9])\\.([0-9])", "\\1,\\2", testo))


# --- PASSO 3. Calcolo, indicatore per indicatore -----------------------------------
cat("\nMISURE DI DISUGUAGLIANZA - indicatori PASSI, Trentino\n")
cat("=====================================================\n")

for (ind in unique(dati$indicator_name)) {
  for (dim in unique(dati$dimension[dati$indicator_name == ind])) {
    g <- dati[dati$indicator_name == ind & dati$dimension == dim, ]
    cat("\n", ind, " - per ", tolower(dim), "\n", sep = "")
    ordinata <- g$ordered_dimension[1] == 1

    if (ordinata) {
      # gruppi in fila: 1 = il più svantaggiato
      g <- g[order(g$subgroup_order), ]
      peggio <- g[1, ]; meglio <- g[nrow(g), ]
    } else {
      # due gruppi: quello indicato come riferimento è il più favorito
      meglio <- g[g$reference_subgroup == 1, ]; peggio <- g[g$reference_subgroup != 1, ]
    }
    for (i in seq_len(nrow(g))) stampa(sprintf("   %-28s %5.1f%%\n", g$subgroup[i], g$estimate[i]))
    stampa(sprintf("   Differenza                   %5.1f punti\n", peggio$estimate - meglio$estimate))
    stampa(sprintf("   Rapporto                     %5.1f volte\n", peggio$estimate / meglio$estimate))

    if (ordinata && all(!is.na(g$population))) {
      quota <- g$population / sum(g$population)
      # Come in HEAT: per gli indicatori sfavorevoli (favourable_indicator = 0) il
      # segno dell'indice di pendenza si rovescia, così un valore positivo vuol dire
      # che il problema pesa di più sui gruppi in fondo alla scala.
      verso <- if (g$favourable_indicator[1] == 0) -1 else 1
      media <- sum(quota * g$estimate)
      if (oms) {
        s <- suppressWarnings(healthequal::sii(est = g$estimate, subgroup_order = g$subgroup_order,
                                               pop = g$population, scaleval = 100))
        r <- suppressWarnings(healthequal::rii(est = g$estimate, subgroup_order = g$subgroup_order,
                                               pop = g$population, scaleval = 100))
        stampa(sprintf("   Indice di pendenza (OMS)     %5.1f punti\n", verso * s$estimate))
        stampa(sprintf("   Indice relativo (OMS)        %5.1f volte\n", 1 / r$estimate))
      } else {
        stampa(sprintf("   Indice di pendenza (a mano)  %5.1f punti\n", verso * pendenza_a_mano(g$estimate, g$population)))
      }
      stampa(sprintf("   Frazione attribuibile        %5.1f%%\n", 100 * (meglio$estimate - media) / media))
    } else {
      cat("   (Le altre misure richiedono la popolazione di ogni gruppo e almeno tre gruppi\n")
      cat("    in fila: per questa dimensione le schede PASSI non danno abbastanza dati.)\n")
    }
  }
}

cat("\nIndice di pendenza: come in HEAT, per gli indicatori da ridurre (sedentarietà,\n")
cat("obesità) un valore positivo vuol dire che il problema pesa di più su chi sta\n")
cat("in fondo alla scala sociale.\n")
if (!oms) {
  cat("\nIl pacchetto healthequal non è installato: l'indice relativo è stato saltato.\n")
  cat("Per installarlo: install.packages(\"healthequal\"), poi rieseguire il programma.\n")
}
cat("\n")
