"""Copertina di un volume della collana Sociologizzando.

Uso, dalla cartella della collana:
    DYLD_FALLBACK_LIBRARY_PATH=/opt/homebrew/lib python3 _Strumenti/genera_copertina.py "1 - Lo sappiamo già"

Legge titolo, sottotitolo per la copertina (due righe) e autore dal volume.json
della cartella del volume, e scrive Copertina/cover.png e cover.svg. Scrive un PNG di 1600x2400 (rapporto 2:3, lo stesso del formato di stampa 6x9")
e l'SVG accanto. La copertina della collana l'ha scelta Gianni il 17 novembre 2026:
- fondo «acqua» (#CFE1DE), testo blu-nero, caratteri Avenir Next;
- in alto COLLANA SOCIOLOGIZZANDO, senza numero del volume, come in Erranze
  (scelta di Gianni del 17 novembre; il numero resta nei metadati dell'epub);
- al centro l'emblema fisso: diciotto figurine alla maniera di Isotype, il
  linguaggio per immagini di Otto Neurath, in petrolio; quattro in colore;
- in basso titolo, sottotitolo su due righe e autore.
La collana è a colori fissi, come Erranze è monocroma: le quattro figurine sono
senape in tutti i volumi (Gianni, 17 novembre 2026). Cambiano solo titolo,
sottotitolo e, se serve, autore. L'opzione --accento resta per le prove.
"""
import argparse
import json
import os

import cairosvg

QUI = os.path.dirname(os.path.abspath(__file__))
BASE = os.path.dirname(QUI)
W, H = 800, 1200                      # unità del disegno; il PNG esce al doppio
FONDO, INK, INK2, PETROLIO = "#CFE1DE", "#1E2A33", "#4B5560", "#2F6E73"
FONT = "Avenir Next"
CX, CY = W / 2, 470
GRUPPO = {(1, 3), (1, 4), (1, 5), (2, 5)}     # le figurine in colore, sempre le stesse


def figurina(x, y, s, colore):
    return (f'<circle cx="{x}" cy="{y - 1.15*s}" r="{0.42*s}" fill="{colore}"/>'
            f'<rect x="{x - 0.5*s}" y="{y - 0.62*s}" width="{s}" height="{1.55*s}" rx="{0.35*s}" fill="{colore}"/>')


def svg(titolo, sotto, accento, autore):
    figure = "\n".join(figurina(CX + (c - 2.5) * 92, CY - 120 + r * 130, 44,
                                accento if (r, c) in GRUPPO else PETROLIO)
                       for r in range(3) for c in range(6))
    corpo_titolo = 78 if len(titolo) <= 17 else 64
    righe = "\n".join(f'<text x="70" y="{955 + 37*k}" font-family="{FONT}" font-weight="500" font-size="27" fill="{INK2}">{r}</text>'
                      for k, r in enumerate(sotto))
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">
<rect width="{W}" height="{H}" fill="{FONDO}"/>
<text x="70" y="96" font-family="{FONT}" font-weight="600" font-size="20" letter-spacing="7" fill="{INK}">COLLANA SOCIOLOGIZZANDO</text>
<line x1="70" y1="122" x2="{W-70}" y2="122" stroke="{INK}" stroke-width="1.2"/>
{figure}
<text x="70" y="900" font-family="{FONT}" font-weight="700" font-size="{corpo_titolo}" fill="{INK}">{titolo}</text>
{righe}
<line x1="70" y1="1078" x2="{W-70}" y2="1078" stroke="{INK}" stroke-width="1.2"/>
<text x="70" y="1124" font-family="{FONT}" font-weight="500" font-size="24" letter-spacing="2" fill="{INK}">{autore}</text>
</svg>"""


def main():
    a = argparse.ArgumentParser()
    a.add_argument("volume", help="cartella del volume, per esempio «1 - Lo sappiamo già»")
    a.add_argument("--accento", default="#D9962A", help="solo per le prove: la collana usa sempre la senape")
    x = a.parse_args()
    cartella = os.path.join(BASE, x.volume)
    v = json.load(open(os.path.join(cartella, "volume.json"), encoding="utf-8"))
    os.makedirs(os.path.join(cartella, "Copertina"), exist_ok=True)
    uscita = os.path.join(cartella, "Copertina", "cover.png")
    testo = svg(v["titolo"], v["sottotitolo_copertina"], x.accento, v["autore"])
    open(os.path.splitext(uscita)[0] + ".svg", "w", encoding="utf-8").write(testo)
    cairosvg.svg2png(bytestring=testo.encode("utf-8"), write_to=uscita,
                     output_width=2 * W, output_height=2 * H)
    print("Scritta:", uscita)


if __name__ == "__main__":
    main()
