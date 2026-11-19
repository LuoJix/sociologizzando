#!/usr/bin/env python3
"""Deposita su Zenodo il libro di un volume (epub e PDF dell'interno).

È il deposito del libro, separato da quello dei materiali, che Zenodo crea da
solo dalle release di GitHub (decisione di Gianni, 18 novembre 2026). Il modello
è carica-zenodo.py della Collana Erranze, con le stesse cautele: la bozza è il
default, perché su Zenodo un DOI non si cancella; dopo un errore della
pubblicazione si rilegge lo stato, perché un 504 non prova che sia fallita.

I metadati vengono da volume.json: titolo e sottotitolo, quarta come
descrizione, parole chiave, anno. Il libro rimanda ai materiali con la relazione
«isSupplementedBy» verso il loro DOI di concetto (campo "materiali"). L'esito
torna in volume.json, sotto "zenodo"; a pubblicazione avvenuta il DOI di
concetto del libro va anche in "ebook", che pubblica.py usa per il README.

Il token è quello di Erranze: ~/.config/zenodo/token, oppure ZENODO_TOKEN.

Uso, dalla cartella della collana:
    python3 _Strumenti/carica_zenodo.py "1 - Lo sappiamo già" --prova     # mostra la scheda, non tocca la rete
    python3 _Strumenti/carica_zenodo.py "1 - Lo sappiamo già"             # bozza da rivedere su zenodo.org
    python3 _Strumenti/carica_zenodo.py "1 - Lo sappiamo già" --pubblica  # pubblica la bozza: il DOI resta
    python3 _Strumenti/carica_zenodo.py "1 - Lo sappiamo già" --nuova-versione [--pubblica]  # dopo una correzione
"""
import html
import json
import os
import sys
import time
from datetime import date

QUI = os.path.dirname(os.path.abspath(__file__))
BASE = os.path.dirname(QUI)
API = "https://zenodo.org/api"
LICENZA = "cc-by-nc-sa-4.0"
COLLANA = "Collana Sociologizzando"
PAROLE_COLLANA = ["ricerca sociale", "dati pubblici", "tutorial"]


def token():
    if os.environ.get("ZENODO_TOKEN"):
        return os.environ["ZENODO_TOKEN"].strip()
    p = os.path.expanduser("~/.config/zenodo/token")
    if os.path.exists(p):
        return open(p, encoding="utf-8").read().strip()
    sys.exit(f"Manca il token: valorizza ZENODO_TOKEN oppure scrivilo in {p}")


def leggi(cartella):
    with open(os.path.join(BASE, cartella, "volume.json"), encoding="utf-8") as f:
        return json.load(f)


def salva(cartella, v):
    with open(os.path.join(BASE, cartella, "volume.json"), "w", encoding="utf-8") as f:
        json.dump(v, f, ensure_ascii=False, indent=2)
        f.write("\n")


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
    doi_materiali = v["materiali"].split("doi.org/")[-1]

    parole = list(PAROLE_COLLANA)
    parole += [p for p in v.get("parole_chiave", []) if p not in parole]
    descrizione = (
        f"<p>{html.escape(v['quarta'], quote=False)}</p>"
        f"<p>Volume {v['numero']} della {COLLANA}: tutorial per fare ricerca sociale con dati "
        f"pubblici e strumenti gratuiti. I materiali per rifare tutti i calcoli (dati, fogli "
        f"elettronici, programmi in R, istruzioni) sono in un deposito a parte: "
        f"<a href=\"{v['materiali']}\">{v['materiali']}</a>.</p>"
        f"<p>Qui l'edizione digitale (epub) e l'interno dell'edizione a stampa (PDF).</p>")
    meta = {
        "upload_type": "publication",
        "publication_type": "book",
        "title": f"{v['titolo']} — {v['sottotitolo']}",
        "creators": [{"name": "Martini, Giovanni"}],
        "description": descrizione,
        "access_right": "open",
        "license": LICENZA,
        "publication_date": str(v.get("anno", date.today().year)),
        "language": "ita",
        "keywords": parole,
        "version": "1.0",
        "notes": f"{COLLANA}, volume {v['numero']}",
        "related_identifiers": [{"relation": "isSupplementedBy", "identifier": doi_materiali,
                                 "resource_type": "dataset"}],
    }
    return files, meta


def verifica_stato(sess, deposit_id, tentativi=5):
    for i in range(tentativi):
        try:
            r = sess.get(f"{API}/deposit/depositions/{deposit_id}", timeout=90)
            if r.status_code == 200:
                d = r.json()
                return d.get("state"), d.get("doi"), d.get("conceptdoi")
        except Exception:                                       # noqa: BLE001
            pass
        time.sleep(10 * (i + 1))
    return None, None, None


def pubblicazione(sess, deposit_id, dati):
    """Il passo che non si annulla. Dopo un errore si rilegge lo stato: sotto
    carico Zenodo risponde 504 dopo aver già pubblicato (Erranze, 19 agosto 2026)."""
    try:
        r = sess.post(f"{API}/deposit/depositions/{deposit_id}/actions/publish", timeout=120)
        codice, corpo = r.status_code, r.text[:200]
    except Exception as e:                                      # noqa: BLE001
        codice, corpo, r = None, f"{type(e).__name__}: {e}", None
    if codice not in (200, 202):
        stato, doi, concept = verifica_stato(sess, deposit_id)
        if stato == "done" and doi:
            dati.update({"doi": doi, "concept_doi": concept, "pubblicato": True,
                         "url": f"https://zenodo.org/records/{deposit_id}"})
            print(f"! risposta {codice}, ma il record risulta pubblicato: {doi}")
            return True
        print(f"✗ pubblicazione fallita ({codice}): {corpo}\n  la bozza resta aperta: {dati['url']}")
        return False
    j = r.json()
    dati.update({"doi": j.get("doi"), "concept_doi": j.get("conceptdoi"), "pubblicato": True,
                 "url": j["links"].get("record_html", dati["url"])})
    print(f"✓ pubblicato: {dati['doi']} (concetto: {dati['concept_doi']})")
    return True


def carica_file(sess, bucket, files):
    for f in files:
        with open(f, "rb") as fh:
            u = sess.put(f"{bucket}/{os.path.basename(f)}", data=fh)
        if u.status_code not in (200, 201):
            print(f"✗ caricamento di {os.path.basename(f)} fallito ({u.status_code})")
            return False
    return True


def segna_pubblicato(cartella, v, dati):
    v["zenodo"] = dati
    if dati.get("concept_doi"):
        v["ebook"] = f"https://doi.org/{dati['concept_doi']}"
    salva(cartella, v)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if len(args) != 1:
        sys.exit(__doc__)
    cartella = args[0]
    prova, pubblica = "--prova" in sys.argv, "--pubblica" in sys.argv
    versionare = "--nuova-versione" in sys.argv

    v = leggi(cartella)
    files, meta = prepara(cartella, v)
    print(f"[{v['numero']}] {meta['title']}")
    for f in files:
        print(f"    {os.path.basename(f)}  ({round(os.path.getsize(f) / 1024)} KB)")
    if prova:
        print(json.dumps(meta, ensure_ascii=False, indent=2))
        return

    import requests
    sess = requests.Session()
    sess.params = {"access_token": token()}
    fatto = v.get("zenodo") or {}

    if versionare:
        if not fatto.get("pubblicato"):
            sys.exit("Non ancora pubblicato: prima il deposito normale.")
        bozza = fatto.get("bozza")
        if not bozza:
            r = sess.post(f"{API}/deposit/depositions/{fatto['deposit_id']}/actions/newversion")
            if r.status_code not in (200, 201):
                sys.exit(f"✗ nuova versione non creata ({r.status_code}): {r.text[:200]}")
            nuovo = int(r.json()["links"]["latest_draft"].rstrip("/").split("/")[-1])
            bozza = {"deposit_id": nuovo, "url": f"https://zenodo.org/deposit/{nuovo}"}
            fatto["bozza"] = bozza
            v["zenodo"] = fatto
            salva(cartella, v)
        d = sess.get(f"{API}/deposit/depositions/{bozza['deposit_id']}").json()
        for f in d.get("files", []):   # la bozza eredita i file vecchi: vanno tolti
            sess.delete(f"{API}/deposit/depositions/{bozza['deposit_id']}/files/{f['id']}")
        if not carica_file(sess, d["links"]["bucket"], files):
            return
        maggiore, minore = fatto.get("versione", "1.0").split(".")[:2]
        meta["version"] = f"{maggiore}.{int(minore) + 1}"
        m = sess.put(f"{API}/deposit/depositions/{bozza['deposit_id']}", json={"metadata": meta})
        if m.status_code != 200:
            sys.exit(f"✗ metadati non aggiornati ({m.status_code}): {m.text[:200]}")
        if not pubblica:
            print(f"✓ versione {meta['version']} pronta da rivedere: {bozza['url']}")
            return
        dati = {"deposit_id": bozza["deposit_id"], "url": bozza["url"], "pubblicato": False}
        if pubblicazione(sess, bozza["deposit_id"], dati):
            dati["versione"] = meta["version"]
            dati["concept_doi"] = dati.get("concept_doi") or fatto.get("concept_doi")
            dati["precedenti"] = (fatto.get("precedenti") or []) + [fatto["doi"]]
            segna_pubblicato(cartella, v, dati)
        return

    if fatto.get("pubblicato"):
        print(f"già depositato: {fatto.get('doi')} (per una correzione serve --nuova-versione)")
        return
    if fatto.get("deposit_id"):
        if pubblica:
            print(f"bozza già aperta, la pubblico: {fatto['url']}")
            if pubblicazione(sess, fatto["deposit_id"], fatto):
                fatto["versione"] = "1.0"
                segna_pubblicato(cartella, v, fatto)
        else:
            print(f"bozza già aperta, la lascio: {fatto['url']}")
        return

    r = sess.post(f"{API}/deposit/depositions", json={"metadata": meta})
    if r.status_code not in (200, 201):
        sys.exit(f"✗ creazione fallita ({r.status_code}): {r.text[:400]}")
    dep = r.json()
    dati = {"deposit_id": dep["id"], "url": dep["links"]["html"], "pubblicato": False}
    riservato = dep.get("metadata", {}).get("prereserve_doi", {})
    if riservato.get("doi"):
        dati["doi_riservato"] = riservato["doi"]
    v["zenodo"] = dati
    salva(cartella, v)
    if not carica_file(sess, dep["links"]["bucket"], files):
        print(f"bozza incompleta, resta aperta: {dati['url']}")
        return
    if pubblica:
        if pubblicazione(sess, dep["id"], dati):
            dati["versione"] = "1.0"
            segna_pubblicato(cartella, v, dati)
    else:
        print(f"✓ bozza pronta da rivedere: {dati['url']}")


if __name__ == "__main__":
    main()
