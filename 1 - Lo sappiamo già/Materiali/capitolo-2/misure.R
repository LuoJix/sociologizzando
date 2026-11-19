# =============================================================================
# Lo sappiamo già - Capitolo 2: le quattro misure
# =============================================================================
#
# Che cosa fa: calcola differenza, rapporto, indice di pendenza e frazione
# attribuibile per i sedentari trentini divisi per titolo di studio.
#
# Come si usa (le istruzioni complete sono nel file LEGGIMI.md):
#   1. aprire questo file in RStudio (menu File -> Open File...);
#   2. premere il pulsante Source, in alto a destra di questo riquadro;
#   3. i risultati compaiono nella console, in basso a sinistra.
#   Senza RStudio: in R scrivere  source(file.choose())  e scegliere questo file.
#
# Le righe che cominciano con # sono commenti: R non le legge, servono a chi
# legge. Per provare con i propri dati basta cambiare i numeri del PASSO 1.
# =============================================================================


# --- PASSO 1. I dati ----------------------------------------------------------
# Tre gruppi, sempre in quest'ordine: dal più svantaggiato al più favorito.

gruppi      <- c("Fino alla licenza media", "Diploma", "Laurea")

# Percentuale di sedentari in ogni gruppo
# (fonte: PASSI 2023-2024, Osservatorio epidemiologico APSS, Trentino, 18-64 anni)
sedentari   <- c(20, 13, 9)

# Quante persone ci sono in ogni gruppo
# (fonte: censimento permanente ISTAT 2024, Trentino, 25-64 anni)
popolazione <- c(61361, 148766, 76964)


# --- PASSO 2. Le due misure semplici ------------------------------------------
# Usano solo il primo e l'ultimo gruppo.

differenza <- sedentari[1] - sedentari[3]
rapporto   <- sedentari[1] / sedentari[3]


# --- PASSO 3. Indice di pendenza, calcolato a mano ----------------------------
# Lo stesso calcolo del foglio elettronico (misure.xlsx), colonna per colonna.

quota <- popolazione / sum(popolazione)        # quota di ogni gruppo sul totale
rango <- cumsum(quota) - quota / 2             # punto medio del gruppo sulla scala da 0 a 1
media <- sum(quota * sedentari)                # media del territorio
colonna_A <- quota * (rango - 0.5) * (sedentari - media)
colonna_B <- quota * (rango - 0.5)^2
pendenza  <- sum(colonna_A) / sum(colonna_B)
# La sedentarietà è un indicatore sfavorevole (da ridurre). Come fa HEAT, per gli
# indicatori sfavorevoli si rovescia il segno: un valore positivo vuol dire che
# il problema pesa di più sui gruppi in fondo alla scala.
pendenza  <- -pendenza


# --- PASSO 4. Frazione attribuibile -------------------------------------------
# Di quanto calerebbe la media se tutti stessero come il gruppo più favorito.

frazione <- (sedentari[3] - media) / media * 100


# --- PASSO 5. Stampa dei risultati --------------------------------------------
# stampa() scrive una riga con la virgola decimale, come si usa in italiano
stampa <- function(testo) cat(gsub("([0-9])\\.([0-9])", "\\1,\\2", testo))

cat("\n")
cat("RISULTATI: sedentari per titolo di studio, Trentino\n")
cat("---------------------------------------------------\n")
for (i in 1:3) {
  stampa(sprintf("  %-25s %5.1f%%   quota della popolazione %5.1f%%\n",
              gruppi[i], sedentari[i], quota[i] * 100))
}
stampa(sprintf("  %-25s %5.1f%%\n", "Media del territorio", media))
cat("\n")
stampa(sprintf("  Differenza                  %5.1f punti\n", differenza))
stampa(sprintf("  Rapporto                    %5.1f volte\n", rapporto))
stampa(sprintf("  Indice di pendenza          %5.1f punti\n", pendenza))
stampa(sprintf("  Frazione attribuibile       %5.1f%%\n", frazione))
cat("\n")
cat("  (La sedentarietà è un indicatore sfavorevole: come nei programmi dell'OMS,\n")
cat("   l'indice di pendenza è positivo quando il problema pesa di più su chi ha\n")
cat("   studiato meno.)\n")


# --- PASSO 6. Le stesse misure con il pacchetto dell'OMS ----------------------
# Questa parte funziona solo se il pacchetto healthequal è installato.
# Se non lo è, il programma lo dice e si ferma qui: i risultati sopra restano validi.

if (requireNamespace("healthequal", quietly = TRUE)) {
  # suppressWarnings nasconde un avviso tecnico del pacchetto, innocuo per questi dati
  sii_oms <- suppressWarnings(healthequal::sii(est = sedentari, subgroup_order = 1:3,
                                               pop = popolazione, scaleval = 100))
  rii_oms <- suppressWarnings(healthequal::rii(est = sedentari, subgroup_order = 1:3,
                                               pop = popolazione, scaleval = 100))
  cat("\n")
  cat("CONTROLLO con il pacchetto dell'OMS (healthequal)\n")
  cat("------------------------------------------------\n")
  stampa(sprintf("  Indice di pendenza          %5.1f punti\n", -sii_oms$estimate))
  stampa(sprintf("  Indice relativo             %5.1f volte (fondo della scala rispetto alla cima)\n",
              1 / rii_oms$estimate))
} else {
  cat("\n")
  cat("Il pacchetto healthequal non è installato: il controllo con il metodo\n")
  cat("dell'OMS è stato saltato. Per installarlo, scrivere in R:\n")
  cat("    install.packages(\"healthequal\")\n")
  cat("e poi rilanciare questo file (vedi LEGGIMI.md).\n")
}
cat("\n")
