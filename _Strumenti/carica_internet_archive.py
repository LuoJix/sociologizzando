#!/usr/bin/env python3
"""Carica su Internet Archive il libro di un volume (epub e PDF dell'interno).

Il modello è carica-internet-archive.py della Collana Erranze, con le stesse
cautele: un item già presente non si duplica (su Internet Archive un item creato
per sbaglio non si cancella, si può solo chiedere di oscurarlo); upload() non
solleva eccezioni sugli errori HTTP, quindi le risposte si controllano una per
una; dopo una correzione serve --sostituisci, che riscrive i file con lo stesso
nome (le versioni precedenti restano nella cronologia dell'item).

Metadati da volume.json: titolo — sottotitolo, quarta, parole chiave della
collana più "parole_chiave", anno, numero del volume. La descrizione rimanda al
deposito Zenodo del libro (campo "zenodo") e ai materiali (campo "materiali").
L'esito torna in volume.json, sotto "internet_archive".

Il client è quello di Erranze, già configurato (ia configure).

Uso, dalla cartella della collana:
    python3 _Strumenti/carica_internet_archive.py "1 - Lo sappiamo già" --prova   # mostra, non carica
    python3 _Strumenti/carica_internet_archive.py "1 - Lo sappiamo già"
    python3 _Strumenti/carica_internet_archive.py "1 - Lo sappiamo già" --completa      # aggiunge i file mancanti
    python3 _Strumenti/carica_internet_archive.py "1 - Lo sappiamo già" --sostituisci   # dopo una correzione
"""
import json
import os
import re
import sys
import unicodedata
from datetime import date

QUI = os.path.dirname(os.path.abspath(__file__))
BASE = os.path.dirname(QUI)
COLLANA = "Collana Sociologizzando"
LICENZA_URL = "https://creativecommons.org/licenses/by-nc-sa/4.0/"
PAROLE_COLLANA = ["ricerca sociale", "dati pubblici", "tutorial"]


def slug(s):
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode()
    return re.sub(r"-+", "-", re.sub(r"[^a-z0-9]+", "-", s.lower())).strip("-")


def prepara(cartella, v):
    src = os.path.join(BASE, cartella)
    files = [os.path.join(src, v["titolo"] + ".epub"),
             os.path.join(src, "Stampa", v["titolo"] + " - Interno.pdf")]
    mancano = [f for f in files if not os.path.exists(f)]
    if mancano:
        sys.exit("Mancano: " + ", ".join(mancano))
    if "(PROVA)" in " ".join(os.listdir(os.path.join(src, "Stampa"))):
        sys.exit("In Stampa/ ci sono PDF di prova: il libro non ha ancora il DOI dei materiali.")
    if not v.get("materiali"):
        sys.exit("Manca il campo \"materiali\" in volume.json: prima il DOI dei materiali.")

    ident = f"{slug(COLLANA)}-{v['numero']:02d}-{slug(v['titolo'])}"
    parole = list(PAROLE_COLLANA)
    parole += [p for p in v.get("parole_chiave", []) if p not in parole]
    altro = (f"Volume {v['numero']} della {COLLANA}: tutorial per fare ricerca sociale con dati "
             f"pubblici e strumenti gratuiti. I materiali per rifare tutti i calcoli (dati, fogli "
             f"elettronici, programmi in R, istruzioni) sono su Zenodo: {v['materiali']}")
    if v.get("ebook"):
        altro += f". Il libro è depositato anche su Zenodo: {v['ebook']}"
    meta = {
        "mediatype": "texts",
        "collection": "opensource",
        "title": f"{v['titolo']} — {v['sottotitolo']}",
        "creator": "Giovanni Martini",
        "date": str(v.get("anno", date.today().year)),
        "language": "ita",
        "subject": parole,
        "description": f"{v['quarta']}\n\n{altro}.",
        "licenseurl": LICENZA_URL,
        "volume": str(v["numero"]),
        "series": COLLANA,
    }
    return ident, files, meta


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if len(args) != 1:
        sys.exit(__doc__)
    cartella = args[0]
    prova = "--prova" in sys.argv
    sostituisci = "--sostituisci" in sys.argv

    p = os.path.join(BASE, cartella, "volume.json")
    with open(p, encoding="utf-8") as f:
        v = json.load(f)
    ident, files, meta = prepara(cartella, v)
    print(f"[{v['numero']}] {ident}")
    for f_ in files:
        print(f"    {os.path.basename(f_)}  ({round(os.path.getsize(f_) / 1024)} KB)")
    if prova:
        print(json.dumps(meta, ensure_ascii=False, indent=2))
        return

    try:
        import internetarchive
        from internetarchive import get_item, upload
    except ImportError:
        sys.exit("Manca la libreria: python3 -m pip install --user internetarchive")
    if not internetarchive.config.get_config().get("s3", {}).get("access"):
        sys.exit("Client non configurato: esegui prima  ia configure")

    item = get_item(ident)
    if item.exists:
        presenti = {f.name for f in item.get_files()}
        mancanti = [f_ for f_ in files if os.path.basename(f_) not in presenti]
        if sostituisci:
            print(f"item presente, sostituisco {len(files)} file (i precedenti restano nella cronologia)")
        elif not mancanti:
            print("item già completo, salto (dopo una correzione serve --sostituisci)")
            return
        elif "--completa" not in sys.argv:
            print(f"item presente ma incompleto ({len(mancanti)} file mancanti): rilancia con --completa")
            return
        else:
            print(f"item presente, aggiungo {len(mancanti)} file mancanti")
            files = mancanti

    risposte = upload(ident, files=files, metadata=meta, retries=20, retries_sleep=30, verbose=True)
    falliti = [r for r in risposte if getattr(r, "status_code", None) not in (200, 201)]
    if falliti:
        for r in falliti:
            print(f"✗ {getattr(r, 'status_code', '?')} su {os.path.basename(getattr(r.request, 'url', '?'))}")
        print("item incompleto: rilancia con --completa quando la coda si libera")
        return
    v["internet_archive"] = {"identifier": ident, "url": f"https://archive.org/details/{ident}"}
    with open(p, "w", encoding="utf-8") as f:
        json.dump(v, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(f"✓ caricato ({len(risposte)} file): https://archive.org/details/{ident}")


if __name__ == "__main__":
    main()
