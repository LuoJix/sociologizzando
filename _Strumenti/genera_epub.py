"""Genera l'epub di un volume della collana Sociologizzando.

Uso, dalla cartella della collana:
    python3 _Strumenti/genera_epub.py "1 - Lo sappiamo già"
    python3 _Strumenti/genera_epub.py "1 - Lo sappiamo già" --definitivo   # senza nota di lavoro, per il deposito

Legge dalla cartella del volume:
    volume.json          titolo, sottotitolo, numero, autore
    <titolo>.md          il testo; la prima riga è la riga di stato in corsivo
    immagini/            le figure richiamate dal testo
    Copertina/cover.png  la copertina (da _Strumenti/genera_copertina.py)
e scrive <titolo>.epub accanto al .md.

La riga di stato diventa una «Nota di lavoro» prima del primo capitolo; ogni
capitolo («# N. Titolo») è un file a sé dell'epub, con l'indice. Nei metadati
il volume porta il nome della collana e il suo numero, che in copertina non c'è.
"""
import json
import os
import subprocess
import sys

QUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, QUI)
import colophon  # noqa: E402  (colophon e indirizzo dei materiali, comuni al cartaceo)
COLLANA = colophon.COLLANA
BASE = os.path.dirname(QUI)

cartella = os.path.join(BASE, sys.argv[1]) if len(sys.argv) > 1 else sys.exit(__doc__)
v = json.load(open(os.path.join(cartella, "volume.json"), encoding="utf-8"))
MD = os.path.join(cartella, v["titolo"] + ".md")
EPUB = os.path.join(cartella, v["titolo"] + ".epub")

righe = open(MD, encoding="utf-8").read().split("\n")
# La riga di stato c'è nel .md privato; nel repository pubblico pubblica.py la
# toglie, e allora l'epub nasce senza «Nota di lavoro». Con --definitivo la
# nota si toglie anche qui: è l'epub da depositare su Zenodo e Internet Archive,
# e gli appunti di lavoro non devono uscire.
righe, nota = colophon.togli_stato(righe, definitivo="--definitivo" in sys.argv)

# Il colophon non si scrive a mano nel .md: lo compone colophon.py da
# volume.json, come in Erranze la testata la inserisce aggiorna-collana.py. Dal
# 18 novembre 2026 il testo sta in colophon.py, comune a epub e cartaceo.
blocco = "::: colophon\n" + "\n\n".join(colophon.paragrafi(v)) + "\n:::\n"
if nota:
    testo = ("> **Nota di lavoro.** " + nota[1:-1] + "\n\n" + blocco + "\n"
             + "\n".join(righe[1:]).lstrip("\n"))
else:
    testo = blocco + "\n" + "\n".join(righe).lstrip("\n")
# L'indirizzo dei materiali compare anche nel testo, nella pagina «I materiali»
# (dal 18 novembre 2026: i capitoli rimandano lì, con il nome della cartella).
# Prima lo script lo metteva solo nel colophon, e l'epub definitivo sarebbe
# uscito con i segnaposto nei capitoli.
testo = colophon.riempi(testo, v)
tmp = EPUB + ".tmp.md"
open(tmp, "w", encoding="utf-8").write(testo)
try:
    subprocess.run(["pandoc", tmp, "-o", EPUB, "--css", os.path.join(QUI, "stile_epub.css"),
                    "--resource-path", cartella,
                    "--toc", "--toc-depth=1", "--split-level=1",
                    "--epub-cover-image", os.path.join(cartella, "Copertina", "cover.png"),
                    "--metadata", "title=" + v["titolo"], "--metadata", "subtitle=" + v["sottotitolo"],
                    "--metadata", "author=" + v["autore"], "--metadata", "lang=it-IT",
                    "--metadata", "toc-title=Indice",
                    "--metadata", "belongs-to-collection=" + COLLANA,
                    "--metadata", "group-position=" + str(v["numero"])]
                   # la quarta di copertina, come in Erranze, fa da descrizione dell'epub
                   + (["--metadata", "description=" + v["quarta"]] if v.get("quarta") else []),
                   check=True)
finally:
    os.remove(tmp)
print("Scritto:", EPUB)
