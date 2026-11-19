#!/usr/bin/env python3
"""Genera l'edizione a stampa (KDP, copertina flessibile) di un volume della
collana Sociologizzando.

Uso, dalla cartella della collana:
    python3 _Strumenti/genera_stampa.py "1 - Lo sappiamo già"

Scrive in <volume>/Stampa/:
    <titolo> - Interno.pdf      interno 6x9", bianco e nero, margini secondo le fasce KDP
    <titolo> - Copertina.pdf    copertina intera (quarta + dorso + fronte), con 0,125" di abbondanza
    copertina-stampa.svg        la stessa copertina, per controllarla
    qr_materiali.svg            il codice QR dell'indirizzo dei materiali (solo con QR_IN_STAMPA)

Finché in volume.json manca il campo "materiali" (il DOI di concetto dei
materiali su Zenodo), il libro esce con il segnaposto, e i due
PDF prendono nel nome «(PROVA)»: servono a vedere l'impaginazione, non vanno
caricati su KDP.

Lo standard di riferimento è quello di Erranze (Progetti culturali/_Collana
Erranze/stampa.md): formato, margini, area sicura della quarta, dorso calcolato
sulla carta crema, pagine bianche mute. Le differenze sono di questa collana:
- i capitoli sono i titoli «# », non «## »; ogni capitolo apre a destra;
- la riga in corsivo sotto il titolo del capitolo è il suo sottotitolo;
- i grafici a colori si sostituiscono con le versioni «_bn», se ci sono;
- tabelle, codice in linea e indirizzi lunghi hanno uno stile proprio;
- nella pagina «I materiali», sotto l'indirizzo, può andare il codice QR
  (qrencode), ma è spento: vedi QR_IN_STAMPA;
- il colophon viene da colophon.py, lo stesso dell'epub;
- la fronte della copertina è Copertina/cover.svg, la stessa dell'epub.
"""
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys

# WeasyPrint e cairosvg sul Mac trovano le librerie di Homebrew solo con questa
# variabile (vedi la memoria «Cairo sul Mac mini»). Va impostata prima che il
# processo parta, quindi lo script si rilancia da sé con la variabile.
if (sys.platform == "darwin" and "DYLD_FALLBACK_LIBRARY_PATH" not in os.environ
        and os.path.isdir("/opt/homebrew/lib")):
    os.execve(sys.executable, [sys.executable] + sys.argv,
              dict(os.environ, DYLD_FALLBACK_LIBRARY_PATH="/opt/homebrew/lib"))

import cairosvg  # noqa: E402
import markdown  # noqa: E402
import weasyprint  # noqa: E402
from PIL import ImageFont  # noqa: E402
from pypdf import PdfReader, PdfWriter  # noqa: E402

QUI = os.path.dirname(os.path.abspath(__file__))
BASE = os.path.dirname(QUI)
sys.path.insert(0, QUI)
import colophon  # noqa: E402

# --- formato e margini: gli stessi di Erranze (stampa.md) -------------------
TRIM_W, TRIM_H = 6.0, 9.0
BLEED = 0.125
# Il dorso si calcola sulla carta crema anche se si ordina la pastalegno: KDP
# chiede di rivederlo solo oltre le 350 pagine (stampa.md, «La carta»).
SPINE_PER_PAGE = 0.0025
TOP_MARGIN = BOTTOM_MARGIN = 0.75
MARGIN_TABLE = [  # (pagine massime della fascia, margine interno, esterno)
    (150, 0.75, 0.50),
    (300, 0.875, 0.50),
    (500, 1.00, 0.50),
    (828, 1.00, 0.50),
]
SPINE_TEXT_MIN_PAGES = 80  # KDP ammette il testo sul dorso solo oltre le 79 pagine

# --- quarta: area sicura di KDP (stampa.md, «La quarta di copertina») -------
BACK_MARGIN = 0.45       # testo a questa distanza dai due tagli (minimo KDP 0,375")
BARCODE_RESERVE = 1.35   # fascia bassa lasciata al codice a barre
BACK_TOP = 1.10          # prima riga dal bordo del file, abbondanza compresa
BACK_MIN_SCALE = 0.75    # sotto questa riduzione la quarta è da accorciare

# --- colori e caratteri della collana (CLAUDE.md, «Il nome e la copertina») --
ACQUA = "#CFE1DE"
INCHIOSTRO = "#1E2A33"    # il colore dei testi in copertina (cover.svg)
PETROLIO = "#2F6E73"
AVENIR = "/System/Library/Fonts/Avenir Next.ttc"
AVENIR_REGULAR, AVENIR_DEMI = 7, 2   # indici nel file .ttc

# La biografia è quella della presentazione della collana, approvata da Gianni
# il 17 novembre 2026 (Presentazione della collana.md, «L'autore»).
BIO = ("Giovanni Martini, sociologo. Dopo aver fatto l'insegnante, ha lavorato per "
       "più di trent'anni alla Provincia autonoma di Trento, fra istruzione e sanità: "
       "ha costruito indicatori, letto e scritto piani, chiesto dati e cercato di farli "
       "usare. I tutorial li prova lui stesso, passo per passo, prima che escano.")

# Il codice QR sotto l'indirizzo dei materiali. Spento per decisione di Gianni
# (18 novembre 2026): i materiali si usano su un computer, e un codice che apre
# la pagina sul telefono porta il lettore dove non può farci niente; l'indirizzo
# è corto e si ricopia. La funzione resta, per un volume i cui materiali si
# possano consultare anche dal telefono: basta mettere True.
QR_IN_STAMPA = False
# La didascalia, decisa con Gianni lo stesso giorno: dice che serve un computer.
DIDASCALIA_QR = ("Inquadrato con la fotocamera del telefono, il codice apre la pagina dei materiali "
                 "su Zenodo; per scaricarli e usarli serve però un computer.")


def margini(pagine):
    for massimo, interno, esterno in MARGIN_TABLE:
        if pagine <= massimo:
            return interno, esterno
    return MARGIN_TABLE[-1][1:]


def escape(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


# ---------------------------------------------------------------------------
# Interno
# ---------------------------------------------------------------------------

def leggi_volume(cartella):
    v = json.load(open(os.path.join(cartella, "volume.json"), encoding="utf-8"))
    righe = open(os.path.join(cartella, v["titolo"] + ".md"), encoding="utf-8").read().split("\n")
    righe, _ = colophon.togli_stato(righe, definitivo=True)  # la nota di lavoro non va in stampa
    testo = colophon.riempi("\n".join(righe).lstrip("\n"), v)
    return v, testo


def genera_qr(url, dest):
    """Il codice QR dell'indirizzo, vettoriale, con correzione d'errore media.
    Il margine bianco attorno lo fa la pagina."""
    subprocess.run(["qrencode", "-t", "SVG", "-l", "M", "-m", "2", "-o", dest, url], check=True)
    return dest


def corpo_html(testo_md, cartella, qr_path, url):
    md = markdown.Markdown(extensions=["extra", "toc", "nl2br", "sane_lists"],
                           extension_configs={"toc": {"permalink": False}})
    html = md.convert(testo_md)

    # ogni capitolo apre a destra; la riga in corsivo che segue è il sottotitolo
    html = re.sub(r'<h1 id="([^"]+)">', r'<h1 id="\1" class="capitolo">', html)
    html = re.sub(r'(</h1>)\s*<p><em>((?:(?!</p>).)*?)</em></p>', r'\1<p class="sottotitolo">\2</p>',
                  html, flags=re.DOTALL)

    # grafici: la versione in bianco e nero, se c'è (l'interno si stampa in grigi)
    def bn(m):
        src = m.group(1)
        base, ext = os.path.splitext(src)
        alt = base + "_bn" + ext
        return f'src="{alt}"' if os.path.exists(os.path.join(cartella, alt)) else m.group(0)
    html = re.sub(r'src="(immagini/[^"]+)"', bn, html)
    html = re.sub(r'<p>(<img [^>]+>)</p>', r'<figure>\1</figure>', html)

    # indirizzi scritti per esteso: vanno a capo dove serve, senza trattino
    html = re.sub(r'<a href="(https?://[^"]+)">(https?://)', r'<a class="url" href="\1">\2', html)

    # il codice QR sotto l'indirizzo dei materiali, nella pagina «I materiali»
    if qr_path:
        m = re.search(r'<p><strong><a class="url" href="' + re.escape(url) + r'">.*?</p>', html)
        if not m:
            sys.exit("Interrotto: nella pagina «I materiali» non trovo l'indirizzo in grassetto, "
                     "sotto cui va il codice QR.")
        figura = (f'<figure class="qr"><img src="{pathlib.Path(qr_path).as_uri()}" alt="Codice QR">'
                  f'<p class="didascalia">{DIDASCALIA_QR}</p></figure>')
        html = html[:m.end()] + figura + html[m.end():]

    voci = [f'<li><a href="#{t["id"]}">{t["name"]}</a></li>'
            for t in md.toc_tokens if t["level"] == 1]
    return html, "<ul>" + "".join(voci) + "</ul>"


def css(v, interno, esterno):
    testatina = escape(v["titolo"].upper())
    return f"""
@page {{
  size: {TRIM_W}in {TRIM_H}in;
  margin-top: {TOP_MARGIN}in; margin-bottom: {BOTTOM_MARGIN}in;
  @top-center {{ content: "{testatina} · {v['autore']}"; font-family: "Avenir Next"; font-size: 7.5pt;
                 letter-spacing: 0.6px; color: #555; }}
  @bottom-center {{ content: counter(page); font-family: Georgia; font-size: 9pt; color: #333; }}
}}
@page :right {{ margin-left: {interno}in; margin-right: {esterno}in; }}
@page :left  {{ margin-left: {esterno}in; margin-right: {interno}in; }}
@page :blank {{ @top-center {{ content: none; }} @bottom-center {{ content: none; }} }}
@page front  {{ margin: 0.9in; @top-center {{ content: none; }} @bottom-center {{ content: none; }} }}
@page toc    {{ @top-center {{ content: none; }} }}

body {{ font-family: Georgia, serif; font-size: 10.5pt; line-height: 1.45; color: #111;
        text-align: justify; hyphens: auto; }}
p {{ margin: 0 0 0.8em 0; orphans: 3; widows: 3; overflow-wrap: break-word; }}
a {{ color: inherit; text-decoration: none; }}
a.url {{ word-break: break-all; hyphens: none; }}
code {{ font-family: Menlo, monospace; font-size: 0.84em; hyphens: none; }}

h1, h2, h3 {{ font-family: "Avenir Next"; color: {INCHIOSTRO}; text-align: left; hyphens: none; }}
h1 {{ font-size: 19pt; font-weight: 600; line-height: 1.2; margin: 0 0 0.35em 0; }}
h1.capitolo {{ break-before: right; margin-top: 1.4in; }}
p.sottotitolo {{ font-style: italic; font-size: 11pt; line-height: 1.35; color: #444;
                 text-align: left; hyphens: none; margin: 0 0 2em 0; }}
h2 {{ font-size: 12pt; font-weight: 600; margin: 1.5em 0 0.5em 0; break-after: avoid; }}
h3 {{ font-size: 10.5pt; font-weight: 500; font-style: italic; margin: 1.2em 0 0.4em 0; break-after: avoid; }}

ul, ol {{ margin: 0 0 0.8em 0; padding-left: 1.3em; }}
li {{ margin: 0 0 0.3em 0; }}

/* la lettera del capitolo 7 e gli altri blocchi: rientrati, in tondo */
blockquote {{ margin: 1em 0; padding-left: 0.9em; border-left: 1.2pt solid #999;
              font-size: 9.5pt; line-height: 1.4; text-align: left; }}
blockquote p {{ margin: 0 0 0.55em 0; }}

/* tabelle in Avenir Next: le cifre di Georgia sono «da testo», di altezze
   diverse, e in colonna si allineano male; le intestazioni non si sillabano */
table {{ width: 100%; border-collapse: collapse; margin: 0.9em 0 1.3em 0;
         font-family: "Avenir Next"; font-size: 8pt; font-variant-numeric: tabular-nums;
         line-height: 1.3; text-align: left; hyphens: auto;
         border-top: 0.9pt solid #222; border-bottom: 0.9pt solid #222; }}
th {{ font-weight: 600; hyphens: none; border-bottom: 0.6pt solid #222; }}
th, td {{ padding: 3pt 4pt; vertical-align: top; }}
tbody tr {{ border-bottom: 0.3pt solid #bbb; }}
tr {{ break-inside: avoid; }}
/* una tabella non si spezza fra due pagine: le tabelle del libro stanno tutte
   in una pagina, e una tabella divisa costringe a voltare per leggerla */
table {{ break-inside: avoid; }}

figure {{ margin: 1.2em 0; break-inside: avoid; }}
figure img {{ display: block; max-width: 100%; max-height: 5.2in; margin: 0 auto; }}
figure.qr img {{ width: 1.1in; height: 1.1in; }}
p.didascalia {{ font-size: 8.5pt; font-style: italic; text-align: center; color: #444; margin: 0.4em 0 0 0; }}

.front {{ page: front; }}
.titolo {{ text-align: center; padding-top: 1.9in; }}
.titolo .collana {{ font-family: "Avenir Next"; font-weight: 600; font-size: 8.5pt; letter-spacing: 3px;
                    color: {PETROLIO}; margin-bottom: 1.1in; }}
.titolo h1 {{ text-align: center; font-size: 26pt; margin-bottom: 0.4em; }}
.titolo .sottotitolo-libro {{ font-style: italic; font-size: 12.5pt; text-align: center;
                              hyphens: none; margin-bottom: 1.6in; }}
.titolo .autore {{ font-family: "Avenir Next"; font-size: 11pt; letter-spacing: 1.5px; text-align: center; }}
.diritti {{ font-size: 8.5pt; line-height: 1.6; padding-top: 2.1in; text-align: left; hyphens: none; }}
.diritti p {{ margin: 0 0 0.7em 0; }}

.indice {{ page: toc; }}
.indice h1 {{ margin-bottom: 1em; }}
.indice ul {{ list-style: none; margin: 0; padding: 0; }}
.indice li {{ margin: 0.55em 0; }}
.indice a {{ display: flex; justify-content: space-between; }}
.indice a::after {{ content: target-counter(attr(href), page); margin-left: 0.5em; }}
"""


def interno_html(v, corpo, indice):
    diritti = "".join(markdown.markdown(p) for p in colophon.paragrafi(v))
    diritti = re.sub(r'<a href="(https?://[^"]+)">', r'<a class="url" href="\1">', diritti)
    sottotitolo = escape(v["sottotitolo"])
    return f"""<!doctype html>
<html lang="it"><head><meta charset="utf-8"><title>{escape(v['titolo'])}</title></head><body>
<div class="front titolo">
  <p class="collana">COLLANA {colophon.COLLANA.upper()}</p>
  <h1>{escape(v['titolo'])}</h1>
  <p class="sottotitolo-libro">{sottotitolo}</p>
  <p class="autore">{escape(v['autore'])}</p>
</div>
<div class="front diritti">{diritti}</div>
<div class="indice"><h1>Indice</h1>{indice}</div>
{corpo}
</body></html>"""


def genera_interno(v, testo, cartella, qr_path, url, dest):
    corpo, indice = corpo_html(testo, cartella, qr_path, url)
    interno, esterno = margini(150)
    for _ in range(3):  # i margini dipendono dalle pagine, e le pagine dai margini
        doc = weasyprint.HTML(string=interno_html(v, corpo, indice), base_url=cartella + os.sep).render(
            stylesheets=[weasyprint.CSS(string=css(v, interno, esterno))])
        pagine = len(doc.pages)
        if margini(pagine) == (interno, esterno):
            break
        interno, esterno = margini(pagine)
    doc.write_pdf(dest)
    return pagine


# ---------------------------------------------------------------------------
# Copertina
# ---------------------------------------------------------------------------

_font = {}


def larghezza(testo, corpo, indice=AVENIR_REGULAR):
    """Larghezza vera del testo in Avenir Next, in unità SVG (100 per pollice),
    a corpo `corpo` unità. Misurarla invece di stimarla tiene il testo dentro
    l'area sicura anche con un carattere più largo di Georgia."""
    if indice not in _font:
        _font[indice] = ImageFont.truetype(AVENIR, 100, index=indice)
    return _font[indice].getlength(testo) * corpo / 100


def a_capo(testo, corpo, misura):
    righe, riga = [], ""
    for parola in testo.split():
        prova = (riga + " " + parola).strip()
        if riga and larghezza(prova, corpo) > misura:
            righe.append(riga)
            riga = parola
        else:
            riga = prova
    if riga:
        righe.append(riga)
    return righe


def quarta(v, x0, larg_pannello, altezza):
    """Quarta di copertina dentro l'area sicura di KDP; se la quarta è lunga il
    corpo si riduce finché ci sta, sotto BACK_MIN_SCALE si ferma e chiede di
    accorciarla (stampa.md: un corpo molto piccolo è il sintomo di una quarta
    troppo lunga, non una soluzione)."""
    u = 100
    sinistra = x0 + (BLEED + BACK_MARGIN) * u
    destra = x0 + larg_pannello - BACK_MARGIN * u
    misura = destra - sinistra
    cima = BACK_TOP * u
    limite = altezza - (BLEED + BARCODE_RESERVE) * u
    paragrafi = [p.strip() for p in v["quarta"].split("\n\n") if p.strip()]

    scala = 1.0
    while True:
        corpo, passo = 14 * scala, 21 * scala
        corpo_bio, passo_bio = max(10, 11 * scala), max(15, 16 * scala)
        blocchi = [a_capo(p, corpo, misura) for p in paragrafi]
        bio = a_capo(BIO, corpo_bio, misura)
        fondo = (cima + 16 + 46 + sum(passo * len(b) for b in blocchi)
                 + passo * 0.6 * (len(blocchi) - 1) + 34 + 26 + 22
                 + passo_bio * (len(bio) - 1) + corpo_bio * 0.25)
        if fondo <= limite:
            break
        if scala <= BACK_MIN_SCALE:
            sys.exit(f"Interrotto: la quarta non ci sta nemmeno a corpo {corpo * 0.72:.1f} pt "
                     f"(sfora di {(fondo - limite) / u:.2f} pollici): va accorciata.")
        scala = round(scala - 0.02, 2)

    out, y = [], cima
    out.append(f'<text x="{sinistra:.1f}" y="{y:.1f}" font-family="Avenir Next" font-weight="600" '
               f'font-size="11" letter-spacing="4" fill="{INCHIOSTRO}">COLLANA {colophon.COLLANA.upper()}</text>')
    y += 16
    out.append(f'<line x1="{sinistra:.1f}" y1="{y:.1f}" x2="{destra:.1f}" y2="{y:.1f}" '
               f'stroke="{INCHIOSTRO}" stroke-width="0.8"/>')
    y += 46
    for i, blocco in enumerate(blocchi):
        if i:
            y += passo * 0.6
        for riga in blocco:
            out.append(f'<text x="{sinistra:.1f}" y="{y:.1f}" font-family="Avenir Next" '
                       f'font-size="{corpo:.2f}" fill="{INCHIOSTRO}">{escape(riga)}</text>')
            y += passo
    y += 34 - passo
    out.append(f'<line x1="{sinistra:.1f}" y1="{y:.1f}" x2="{destra:.1f}" y2="{y:.1f}" '
               f'stroke="{PETROLIO}" stroke-width="0.6"/>')
    y += 26
    out.append(f'<text x="{sinistra:.1f}" y="{y:.1f}" font-family="Avenir Next" font-weight="600" '
               f'font-size="10" letter-spacing="2" fill="{PETROLIO}">{escape(v["autore"].upper())}</text>')
    y += 22
    for riga in bio:
        out.append(f'<text x="{sinistra:.1f}" y="{y:.1f}" font-family="Avenir Next" '
                   f'font-size="{corpo_bio:.2f}" fill="{INCHIOSTRO}">{escape(riga)}</text>')
        y += passo_bio
    return "\n".join(out), scala, corpo


def dorso(v, x0, larg, altezza, pagine):
    if pagine < SPINE_TEXT_MIN_PAGES:
        return ""
    corpo = min(11, larg - 12.5)  # almeno 0,0625" di aria per lato (KDP)
    if corpo < 6:
        return ""
    cx, cy = x0 + larg / 2, altezza / 2
    testo = escape(f"{v['titolo'].upper()}  ·  {v['autore'].upper()}")
    return (f'<g transform="translate({cx:.1f},{cy:.1f}) rotate(-90)">'
            f'<text x="0" y="0" text-anchor="middle" dominant-baseline="central" '
            f'font-family="Avenir Next" font-weight="600" font-size="{corpo:.1f}" '
            f'letter-spacing="1.5" fill="{INCHIOSTRO}">{testo}</text></g>')


def genera_copertina(v, cartella, pagine, dest_svg, dest_pdf):
    u = 100
    dorso_in = round(max(pagine, 24) * SPINE_PER_PAGE, 3)
    W = (TRIM_W * 2 + dorso_in + BLEED * 2) * u
    H = (TRIM_H + BLEED * 2) * u
    pannello = (BLEED + TRIM_W) * u          # la quarta, abbondanza sinistra compresa
    x_dorso, x_fronte = pannello, pannello + dorso_in * u

    fronte = open(os.path.join(cartella, "Copertina", "cover.svg"), encoding="utf-8").read()
    m = re.search(r'<svg[^>]*viewBox="([^"]+)"[^>]*>(.*)</svg>', fronte, re.DOTALL)
    if not m:
        sys.exit("Interrotto: Copertina/cover.svg non ha la forma attesa.")
    viewbox, interno_fronte = m.group(1), m.group(2)

    testo_quarta, scala, corpo = quarta(v, 0, pannello, H)
    svg = f"""<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="{W / u}in" height="{H / u}in" viewBox="0 0 {W:.1f} {H:.1f}">
<rect width="{W:.1f}" height="{H:.1f}" fill="{ACQUA}"/>
{testo_quarta}
{dorso(v, x_dorso, dorso_in * u, H, pagine)}
<svg x="{x_fronte:.1f}" y="{BLEED * u:.1f}" width="{TRIM_W * u:.1f}" height="{TRIM_H * u:.1f}" viewBox="{viewbox}">
{interno_fronte}
</svg>
</svg>"""
    open(dest_svg, "w", encoding="utf-8").write(svg)
    cairosvg.svg2pdf(url=dest_svg, write_to=dest_pdf)
    return dorso_in, scala, corpo


# ---------------------------------------------------------------------------

def metadati(path, v):
    reader, writer = PdfReader(path), PdfWriter()
    writer.append(reader)
    anno = colophon.anno(v)
    writer.add_metadata({
        "/Title": f"{v['titolo']} — {v['sottotitolo']}",
        "/Author": v["autore"],
        "/Subject": v["sottotitolo"],
        "/Creator": f"Collana {colophon.COLLANA}",
        "/Producer": f"Collana {colophon.COLLANA}",
        "/CreationDate": f"D:{anno}0101000000",
        "/ModDate": f"D:{anno}0101000000",
    })
    with open(path, "wb") as f:
        writer.write(f)


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    cartella = os.path.join(BASE, sys.argv[1])
    v, testo = leggi_volume(cartella)
    stampa = os.path.join(cartella, "Stampa")
    os.makedirs(stampa, exist_ok=True)

    url = v.get("materiali")
    prova = "" if url else " (PROVA)"
    for vecchio in os.listdir(stampa):  # niente PDF di un giro precedente che possano confondersi
        if vecchio.endswith(".pdf"):
            os.remove(os.path.join(stampa, vecchio))

    qr = genera_qr(url, os.path.join(stampa, "qr_materiali.svg")) if url and QR_IN_STAMPA else None
    interno = os.path.join(stampa, f"{v['titolo']} - Interno{prova}.pdf")
    pagine = genera_interno(v, testo, cartella, qr, url, interno)
    print(f"Interno: {pagine} pagine, margini {margini(pagine)[0]}\" interno e {margini(pagine)[1]}\" esterno")

    copertina = os.path.join(stampa, f"{v['titolo']} - Copertina{prova}.pdf")
    dorso_in, scala, corpo = genera_copertina(v, cartella, pagine,
                                              os.path.join(stampa, "copertina-stampa.svg"), copertina)
    ridotta = "" if scala == 1.0 else f", ridotta al {scala:.0%}"
    testo_dorso = "con testo" if pagine >= SPINE_TEXT_MIN_PAGES else "senza testo (meno di 80 pagine)"
    print(f"Copertina: dorso {dorso_in:.3f}\" {testo_dorso}; quarta a corpo {corpo * 0.72:.1f} pt{ridotta}")

    for path in (interno, copertina):
        metadati(path, v)
    if not url:
        print("ATTENZIONE: in volume.json manca il DOI dei materiali. Il libro ha il segnaposto: "
              "questi PDF sono di prova e non vanno caricati su KDP.")
    print(f"Scritti in {os.path.relpath(stampa, BASE)}/")


if __name__ == "__main__":
    main()
