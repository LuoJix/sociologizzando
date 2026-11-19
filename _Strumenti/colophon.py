"""Il colophon e l'indirizzo dei materiali, comuni all'epub e al cartaceo.

Lo usano genera_epub.py e genera_stampa.py. Sta in un file solo perché epub e
cartaceo dello stesso volume dichiarino per forza le stesse cose: in Erranze la
formula sull'AI vive in due script, e va ricordato di cambiarla in tutti e due
(lo segnala stampa.md). Qui il problema non si pone.

La dichiarazione sull'AI comincia con la formula di Erranze (AI_IT in
aggiorna-collana.py: se cambia là, va cambiata anche qui) e aggiunge i
programmi, la sola parte che Gianni non avrebbe saputo fare da sé (decisione del
17 novembre 2026).
"""
import datetime

COLLANA = "Sociologizzando"
SEGNAPOSTO = "[indirizzo dei materiali da completare]"


def anno(v):
    """Campo facoltativo "anno" di volume.json; se manca, l'anno in corso."""
    return v.get("anno") or datetime.date.today().year


def materiali(v):
    """L'indirizzo dei materiali in markdown: l'URL del DOI di concetto di
    Zenodo (campo "materiali" di volume.json) fra parentesi angolari, perché
    diventi un collegamento; finché manca, il segnaposto."""
    return f"<{v['materiali']}>" if v.get("materiali") else SEGNAPOSTO


def riempi(testo, v):
    """Sostituisce il segnaposto dei materiali in tutto il testo."""
    return testo.replace(SEGNAPOSTO, materiali(v))


def paragrafi(v):
    """Il colophon, paragrafo per paragrafo, in markdown."""
    a = anno(v)
    return [
        f"Collana {COLLANA} · {v['numero']} — {v['autore']}",
        f"© {a} {v['autore']}. Il testo è distribuito con licenza Creative Commons BY-NC-SA 4.0 "
        "(<https://creativecommons.org/licenses/by-nc-sa/4.0/deed.it>): si può copiare e adattare "
        "citando l'autore, senza scopo di lucro e condividendo allo stesso modo.",
        "I materiali per rifare i conti (dati, fogli elettronici, programmi in R e istruzioni) sono "
        f"pubblicati a parte: {materiali(v)} (come si scaricano lo spiega la pagina «I materiali»). "
        "I programmi sono distribuiti con licenza MIT; i dati restano delle loro fonti, citate in "
        "fondo a ogni capitolo.",
        "Il testo è stato scritto dall'autore; strumenti di intelligenza artificiale sono stati "
        "utilizzati come supporto editoriale (rifinitura linguistica e coerenza del testo). I "
        "programmi in R dei materiali sono stati scritti con strumenti di intelligenza artificiale, "
        "e provati dall'autore passo per passo.",
        "In copertina, l'emblema della collana: diciotto figurine alla maniera di Isotype, il "
        "linguaggio per immagini di Otto Neurath.",
        f"Prima edizione: {a}",
    ]


def togli_stato(righe, definitivo=True):
    """La prima riga del .md privato è la riga di stato in corsivo («*Stato:
    …*»). Restituisce (righe senza la riga di stato se definitivo, nota o None)."""
    nota = righe[0].strip() if righe else ""
    if not (nota.startswith("*Stato:") and nota.endswith("*")):
        return righe, None
    if definitivo:
        return righe[1:], None
    return righe, nota
