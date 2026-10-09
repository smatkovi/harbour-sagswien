#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Macht aus dem Android-Startsymbol eine PNG-Vorlage fuer make-icons.py.

Das Symbol der Original-App ist ein "adaptive icon" aus zwei
VectorDrawable-Dateien (Hintergrund und Vordergrund). Das laesst sich
umrechnen statt nachzeichnen, weil Androids `android:pathData` **genau**
die Pfadsprache von SVG ist -- uebernommen wird sie wortwoertlich.

Umzusetzen sind nur drei Dinge:
  * <vector> viewportWidth/Height  -> viewBox
  * <group> scaleX/scaleY/translateX/translateY -> transform (erst
    verschieben, dann skalieren -- Android wendet es in dieser Reihenfolge an)
  * <clip-path> -> <clipPath> mit Verweis

Was Android sonst noch kann (Verlaeufe, Striche, Pfadanimation), kommt in
diesem Symbol nicht vor; taucht es auf, bricht das Skript ab, statt still
etwas Falsches zu zeichnen.

    python3 tools/vector2png.py            -> tools/original/original-1024.png
"""
import os
import sys
import xml.etree.ElementTree as ET

import cairosvg
from PIL import Image

HIER = os.path.dirname(os.path.abspath(__file__))
QUELLE = os.path.join(HIER, "original")
GROESSE = 1024

A = "{http://schemas.android.com/apk/res/android}"


def farbe(wert):
    """#AARRGGBB (Android) -> #RRGGBB + Deckung (SVG)."""
    wert = wert.strip()
    if wert.startswith("#") and len(wert) == 9:
        deckung = int(wert[1:3], 16) / 255.0
        return "#" + wert[3:], deckung
    return wert, 1.0


def gruppe_transform(element):
    sx = float(element.get(A + "scaleX", 1))
    sy = float(element.get(A + "scaleY", 1))
    tx = float(element.get(A + "translateX", 0))
    ty = float(element.get(A + "translateY", 0))
    teile = []
    if tx or ty:
        teile.append("translate(%g %g)" % (tx, ty))
    if sx != 1 or sy != 1:
        teile.append("scale(%g %g)" % (sx, sy))
    return " ".join(teile)


def pfade(element, zaehler):
    """Die Kinder eines Knotens als SVG-Zeilen."""
    raus = []
    for kind in element:
        kurz = kind.tag.split("}")[-1]
        if kurz == "path":
            daten = kind.get(A + "pathData")
            if not daten:
                continue
            fuell, deckung = farbe(kind.get(A + "fillColor", "#ff000000"))
            regel = kind.get(A + "fillType", "nonZero")
            regel = "evenodd" if regel.lower() == "evenodd" else "nonzero"
            stil = 'fill="%s" fill-rule="%s"' % (fuell, regel)
            if deckung < 1.0:
                stil += ' fill-opacity="%g"' % deckung
            if kind.get(A + "strokeColor"):
                sys.exit("Strich im Pfad -- von Hand ansehen, nicht raten")
            raus.append('<path %s d="%s"/>' % (stil, daten))
        elif kurz == "group":
            zaehler[0] += 1
            # Ein <clip-path> gilt fuer die Geschwister in derselben Gruppe.
            schnitt = None
            for enkel in kind:
                if enkel.tag.split("}")[-1] == "clip-path":
                    schnitt = enkel.get(A + "pathData")
            name = "schnitt%d" % zaehler[0]
            kopf = []
            if schnitt:
                kopf.append('<clipPath id="%s"><path d="%s"/></clipPath>'
                            % (name, schnitt))
            auf = '<g'
            tr = gruppe_transform(kind)
            if tr:
                auf += ' transform="%s"' % tr
            if schnitt:
                auf += ' clip-path="url(#%s)"' % name
            auf += '>'
            raus.extend(kopf)
            raus.append(auf)
            raus.extend(pfade(kind, zaehler))
            raus.append('</g>')
        elif kurz == "clip-path":
            pass
        else:
            sys.exit("unbekanntes Element <%s> -- von Hand ansehen" % kurz)
    return raus


def nach_svg(datei):
    baum = ET.parse(datei).getroot()
    breite = baum.get(A + "viewportWidth", "1024")
    hoehe = baum.get(A + "viewportHeight", "1024")
    zeilen = pfade(baum, [0])
    return ('<svg xmlns="http://www.w3.org/2000/svg" '
            'viewBox="0 0 %s %s" width="%d" height="%d">%s</svg>'
            % (breite, hoehe, GROESSE, GROESSE, "".join(zeilen)))


def rendern(datei):
    svg = nach_svg(datei)
    roh = os.path.join(QUELLE, os.path.basename(datei).replace(".xml", ".png"))
    cairosvg.svg2png(bytestring=svg.encode("utf-8"), write_to=roh,
                     output_width=GROESSE, output_height=GROESSE)
    with open(roh.replace(".png", ".svg"), "w", encoding="utf-8") as f:
        f.write(svg)
    return Image.open(roh).convert("RGBA")


def main():
    hintergrund = rendern(os.path.join(QUELLE, "ic_launcher_background.xml"))
    vordergrund = rendern(os.path.join(QUELLE, "ic_launcher_foreground.xml"))
    zusammen = Image.alpha_composite(hintergrund, vordergrund)
    ziel = os.path.join(QUELLE, "original-%d.png" % GROESSE)
    zusammen.save(ziel)
    print("geschrieben:", ziel, zusammen.size)


if __name__ == "__main__":
    main()
