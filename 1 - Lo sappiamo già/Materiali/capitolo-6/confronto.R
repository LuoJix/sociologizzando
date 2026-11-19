# =============================================================================
# Lo sappiamo già - Capitolo 6: Trentino e Italia a confronto
# =============================================================================
#
# Che cosa fa: calcola le misure di disuguaglianza della mortalità fra i 30 e
# i 69 anni per titolo di studio (2022), per il Trentino e per l'Italia, e le
# mette una accanto all'altra.
#
# Come si usa: aprirlo in RStudio (File -> Open File...) e premere Source.
# Senza RStudio: in R scrivere  source(file.choose())  e scegliere questo file.
# Usa il pacchetto healthequal dell'OMS per l'indice relativo, se è installato.
# =============================================================================


# --- PASSO 1. I dati ----------------------------------------------------------
# Quattro gruppi, dal più svantaggiato al più favorito:
# nessun titolo o licenza elementare, licenza media, diploma, laurea.

# Tassi standardizzati di mortalità, 30-69 anni, ogni 10.000 abitanti, 2022
# (ISTAT, «Indicatori di mortalità per causa e titolo di studio»; si scaricano
# con il programma del capitolo 3)
mortalita_trentino <- c(30.9, 29.2, 21.1, 14.6)
mortalita_italia   <- c(44.3, 34.8, 25.5, 19.0)

# Popolazione di 25-64 anni per titolo di studio, 2022
# (ISTAT, censimento permanente: la classe d'età più vicina ai 30-69 anni)
popolazione_trentino <- c(7411, 56280, 149874, 72979)
popolazione_italia   <- c(1507660, 8887717, 14133526, 7109450)


# --- PASSO 2. Le misure ---------------------------------------------------------
oms <- requireNamespace("healthequal", quietly = TRUE)

misure <- function(valori, pop) {
  quota <- pop / sum(pop)
  rango <- cumsum(quota) - quota / 2
  media <- sum(quota * valori)
  if (oms) {
    sii <- suppressWarnings(healthequal::sii(est = valori, subgroup_order = 1:4, pop = pop,
                                             scaleval = 10000))$estimate
    rii <- 1 / suppressWarnings(healthequal::rii(est = valori, subgroup_order = 1:4, pop = pop,
                                                 scaleval = 10000))$estimate
  } else {
    sii <- sum(quota * (rango - 0.5) * (valori - media)) / sum(quota * (rango - 0.5)^2)
    rii <- NA
  }
  c(differenza = valori[1] - valori[4],
    rapporto   = valori[1] / valori[4],
    pendenza   = -sii,   # mortalità: indicatore sfavorevole, segno rovesciato come in HEAT
    relativo   = rii,
    frazione   = 100 * (valori[4] - media) / media)
}

trentino <- misure(mortalita_trentino, popolazione_trentino)
italia   <- misure(mortalita_italia, popolazione_italia)


# --- PASSO 3. Stampa ------------------------------------------------------------------
stampa <- function(testo) cat(gsub("([0-9])\\.([0-9])", "\\1,\\2", testo))
nomi <- c(differenza = "Differenza fra il primo e l'ultimo gruppo",
          rapporto   = "Rapporto fra il primo e l'ultimo gruppo",
          pendenza   = "Indice di pendenza (morti ogni 10 mila)",
          relativo   = "Indice relativo",
          frazione   = "Frazione attribuibile (%)")

cat("\nMORTALITÀ 30-69 ANNI PER TITOLO DI STUDIO, 2022: TRENTINO E ITALIA\n")
cat("-------------------------------------------------------------------\n")
stampa(sprintf("%-44s %10s %10s\n", "", "Trentino", "Italia"))
for (m in names(nomi)) {
  if (is.na(trentino[[m]])) next
  stampa(sprintf("%-44s %10.1f %10.1f\n", nomi[[m]], trentino[[m]], italia[[m]]))
}
cat("\nLe misure assolute (differenza, indice di pendenza) sono più piccole in Trentino;\n")
cat("quelle relative (indice relativo, frazione attribuibile) quasi uguali.\n")
cat("Indice di pendenza: come in HEAT, per un indicatore da ridurre come la mortalità\n")
cat("un valore positivo vuol dire che pesa di più su chi ha studiato meno.\n")
if (!oms) {
  cat("\nIl pacchetto healthequal non è installato: l'indice relativo è stato saltato\n")
  cat("e l'indice di pendenza è calcolato a mano (versione lineare).\n")
}
cat("\n")
