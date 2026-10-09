import QtQuick 1.1
import com.nokia.meego 1.0
import QtMobility.gallery 1.1

// Ein Foto aus der Galerie waehlen.
//
// Harmattan hat keinen fertigen Bildwaehler zum Einbinden; der Weg ist
// DocumentGalleryModel aus QtMobility -- dasselbe Modell, aus dem die
// Galerie-App selbst liest. Sortiert wird nach Aufnahmedatum rueckwaerts:
// wer eine Meldung macht, hat das Foto gerade eben geschossen.
Sheet {
    id: blatt

    signal picked(string datei)

    acceptButtonText: ""
    rejectButtonText: qsTr("Abbrechen")

    title: Rectangle {
        anchors.fill: parent
        color: AppTheme.rot

        Label {
            anchors.verticalCenter: parent.verticalCenter
            x: 16
            font.pixelSize: 26
            color: AppTheme.weiss
            text: qsTr("Foto wählen")
        }
    }

    content: Item {
        anchors.fill: parent

        GridView {
            id: raster
            anchors.fill: parent
            cellWidth: Math.floor(width / 3)
            cellHeight: cellWidth
            clip: true

            model: DocumentGalleryModel {
                rootType: DocumentGallery.Image
                properties: ["url", "dateTaken", "fileName"]
                sortProperties: ["-dateTaken"]
                autoUpdate: false
            }

            delegate: Item {
                width: raster.cellWidth
                height: raster.cellHeight

                Image {
                    anchors.fill: parent
                    anchors.margins: 2
                    fillMode: Image.PreserveAspectCrop
                    clip: true
                    asynchronous: true
                    // Vorschau klein laden -- ein volles Foto je Kachel
                    // bringt das N9 ins Schwitzen.
                    sourceSize.width: raster.cellWidth
                    sourceSize.height: raster.cellHeight
                    source: url
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        // Die Galerie liefert eine file://-Adresse; die API
                        // will einen Pfad.
                        var s = String(url)
                        blatt.picked(s.indexOf("file://") === 0 ? s.substring(7) : s)
                        blatt.reject()
                    }
                }
            }
        }

        ScrollDecorator { flickableItem: raster }

        Label {
            anchors.centerIn: parent
            color: AppTheme.grau
            visible: raster.count === 0
            text: qsTr("Keine Bilder gefunden")
        }
    }
}
