import QtQuick 2.0
// Eine Rasterkarte von basemap.at / Stadt Wien (CC BY 4.0).
//
// Warum selbst gezeichnet: die Original-App nimmt MapLibre fuer
// Vektorkacheln -- das gibt es weder auf Sailfish noch auf Harmattan. Die
// Stadt liefert dieselbe Gegend als 256er-Rasterkacheln, und ein Raster
// zeichnet man in QML in hundert Zeilen.
//
// Die Kacheln kommen durch Images (C++): auf Harmattan kann Qt 4.7 die
// https-Adresse nicht selbst holen, und der Server spricht kein http.
//
// Zwei Dinge, die hier leicht schiefgehen:
//   * Die Kachelordnung ist {z}/{y}/{x} -- Zeile vor Spalte, nicht wie bei
//     OSM. Nachgemessen; vertauscht gibt es 404, aber erst abseits der
//     Diagonale faellt es auf.
//   * Qt 4.7s JavaScript kennt kein Math.asinh. Die Mercator-Umrechnung
//     steht deshalb ausgeschrieben.
Item {
    id: karte

    property real centerLat: 48.2082      // Stephansdom
    property real centerLon: 16.3738
    property int zoom: 15
    property int minZoom: 11
    property int maxZoom: 19

    // Ein Stecknadelkopf, den der Aufrufer setzt (oder nicht).
    property bool showPin: false
    property real pinLat: 0
    property real pinLon: 0

    // Wird beim Ziehen und Zoomen laufend neu gesetzt.
    signal moved(real latitude, real longitude)

    clip: true

    // Kein "readonly property": das kennt QtQuick 1.1 nicht, und der
    // QML-Pruefer der MeeGo-Ausgabe beanstandet es ("Readonly not yet
    // supported"). Derselbe Rumpf dient beiden Ausgaben, also bleibt es
    // hier weg.
    property int tileSize: 256
    property real worldSize: tileSize * Math.pow(2, zoom)

    // Mercator, ausgeschrieben: asinh(x) = ln(x + sqrt(x*x + 1)).
    function lonToWorld(lon) {
        return (lon + 180.0) / 360.0 * worldSize
    }
    function latToWorld(lat) {
        var t = Math.tan(lat * Math.PI / 180.0)
        var s = Math.log(t + Math.sqrt(t * t + 1.0))
        return (1.0 - s / Math.PI) / 2.0 * worldSize
    }
    function worldToLon(wx) {
        return wx / worldSize * 360.0 - 180.0
    }
    function worldToLat(wy) {
        var n = Math.PI * (1.0 - 2.0 * wy / worldSize)
        return 180.0 / Math.PI * Math.atan(0.5 * (Math.exp(n) - Math.exp(-n)))
    }

    // Die linke obere Ecke des Sichtfensters in Weltpixeln.
    property real originX: lonToWorld(centerLon) - width / 2
    property real originY: latToWorld(centerLat) - height / 2

    property int firstTileX: Math.floor(originX / tileSize)
    property int firstTileY: Math.floor(originY / tileSize)
    property int tilesAcross: Math.ceil(width / tileSize) + 1
    property int tilesDown: Math.ceil(height / tileSize) + 1

    Rectangle {
        anchors.fill: parent
        color: "#e8e4dc"
    }

    Repeater {
        model: karte.tilesAcross * karte.tilesDown

        Image {
            // Zeilenweise durchzaehlen: index -> Spalte, Zeile.
            property int tileX: karte.firstTileX + (index % karte.tilesAcross)
            property int tileY: karte.firstTileY + Math.floor(index / karte.tilesAcross)

            width: karte.tileSize
            height: karte.tileSize
            x: tileX * karte.tileSize - karte.originX
            y: tileY * karte.tileSize - karte.originY
            asynchronous: true
            // Images.revision steht im Aufruf, damit die Bindung neu
            // rechnet, sobald die Kachel geholt ist.
            source: Images.tile(karte.zoom, tileX, tileY, Images.revision)
        }
    }

    // Der Stecknadelkopf. Ein Kreis mit Spitze waere schoener, aber auf
    // dem N9 ist jedes Canvas teuer -- zwei Rechtecke tun es.
    Item {
        visible: karte.showPin
        x: karte.lonToWorld(karte.pinLon) - karte.originX
        y: karte.latToWorld(karte.pinLat) - karte.originY

        Rectangle {
            width: 14
            height: 14
            radius: 7
            x: -7
            y: -7
            color: "#e8453c"
            border.color: "white"
            border.width: 2
        }
    }

    MouseArea {
        anchors.fill: parent
        property real lastX: 0
        property real lastY: 0

        onPressed: {
            lastX = mouseX
            lastY = mouseY
        }

        onPositionChanged: {
            // In Weltpixeln verschieben und zurueckrechnen -- so bleibt
            // die Bewegung bei jedem Zoom gleich schnell unter dem Finger.
            var wx = karte.lonToWorld(karte.centerLon) - (mouseX - lastX)
            var wy = karte.latToWorld(karte.centerLat) - (mouseY - lastY)
            lastX = mouseX
            lastY = mouseY
            karte.centerLon = karte.worldToLon(wx)
            karte.centerLat = karte.worldToLat(wy)
            karte.moved(karte.centerLat, karte.centerLon)
        }
    }

    function zoomIn() {
        if (zoom < maxZoom)
            zoom = zoom + 1
    }
    function zoomOut() {
        if (zoom > minZoom)
            zoom = zoom - 1
    }
    function goTo(lat, lon) {
        centerLat = lat
        centerLon = lon
        moved(lat, lon)
    }
}
