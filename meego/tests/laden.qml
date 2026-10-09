// Laedt jede Seite der MeeGo-Ausgabe **auf dem Geraet**, mit dem echten
// com.nokia.meego, und sagt, woran eine scheitert.
//
// Warum das noetig ist, obwohl meego/tests/check-qml.sh schon prueft: der
// Pruefer laeuft auf dem Baurechner ohne com.nokia.meego und blendet
// darum alle "is not a type"-Fehler aus -- also genau die Klasse von
// Fehlern, die eine Komponente betrifft, die es in dieser Fassung der
// Bibliothek nicht gibt. Die sieht man erst hier.
//
// Benutzung: diese Datei als /opt/harbour-sagswien/qml/main.qml
// unterschieben, die App starten, das Log lesen, main.qml zuruecklegen.
// meego/tests/seiten-laden.sh macht genau das.
import QtQuick 1.1
import com.nokia.meego 1.0

PageStackWindow {
    id: appWindow
    initialPage: Page { }

    Component.onCompleted: {
        var dateien = ["AboutPage.qml", "Detail.qml", "Header.qml",
                       "MainPage.qml", "MapPage.qml", "NewReportPage.qml",
                       "PhotoPicker.qml", "ReportPage.qml",
                       "SettingsPage.qml", "TileMap.qml"]
        var schlecht = 0
        for (var i = 0; i < dateien.length; i++) {
            var c = Qt.createComponent(dateien[i])
            if (c.status === Component.Error) {
                schlecht++
                console.log("FEHLER in " + dateien[i] + ": " + c.errorString())
            } else if (c.status !== Component.Ready) {
                schlecht++
                console.log("FEHLER in " + dateien[i] + ": Status " + c.status)
            } else {
                // Anlegen, nicht nur uebersetzen -- manche Fehler kommen
                // erst beim Erzeugen heraus.
                var o = c.createObject(appWindow)
                if (o === null) {
                    schlecht++
                    console.log("FEHLER beim Erzeugen von " + dateien[i]
                                + ": " + c.errorString())
                } else {
                    o.destroy()
                }
            }
        }
        console.log("PRUEFUNG FERTIG: " + dateien.length + " Seiten, "
                    + schlecht + " mit Fehler")
        Qt.quit()
    }
}
