import QtQuick 1.1
import com.nokia.meego 1.0
import Qt.labs.folderlistmodel 1.0

// Ein Foto aus den Bilderordnern waehlen.
//
// **Nicht ueber die Galerie.** Der naheliegende Weg waere
// QtMobilitys DocumentGalleryModel, so wie es die Galerie-App tut -- aber
// der liest den Tracker-Index direkt aus ~/.cache/tracker, und das
// Verzeichnis gehoert `metadata-users` mit Modus `d---rwx---`: der
// Eigentuemer selbst hat keine Rechte darauf. Am N950 nachgemessen: als
// `user` liefert jede Galerieabfrage 0 Treffer, derselbe Lauf als root
// 51 bzw. 1709. (`tracker-sparql` auf der Kommandozeile zeigt trotzdem
// Zahlen -- das geht ueber D-Bus und fuehrt hier in die Irre.)
// Sich die Gruppe im aegis-Manifest zu holen, scheitert ebenfalls: aegis
// lehnt ein selbstgebautes Paket dann **ganz** ab.
//
// Die Dateien selbst sind fuer `user` lesbar. Also gehen wir ueber das
// Dateisystem -- keine Rechte noetig, und man sieht genau die Ordner,
// in denen Bilder liegen.
Sheet {
    id: blatt

    signal picked(string datei)

    property string wurzel: "file:///home/user/MyDocs"

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

        // Die Ordner, in denen auf diesem Geraet Bilder liegen. Ein
        // Baum zum Durchblaettern waere mehr, als man hier braucht:
        // Qt 4.7s FolderListModel kennt keine Rolle, an der sich ein
        // Ordner von einer Datei unterscheiden liesse (fileIsDir und
        // get() gibt es erst spaeter), also waere das Blaettern gebastelt.
        Row {
            id: leiste
            width: parent.width
            height: 64

            Repeater {
                model: [
                    { name: QT_TR_NOOP("Kamera"), pfad: "/home/user/MyDocs/DCIM" },
                    { name: QT_TR_NOOP("Bilder"), pfad: "/home/user/MyDocs/Pictures" },
                    { name: QT_TR_NOOP("Geladen"), pfad: "/home/user/MyDocs/Downloads" }
                ]

                Item {
                    width: leiste.width / 3
                    height: leiste.height

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        color: bilder.folder === "file://" + modelData.pfad
                               ? AppTheme.rot : AppTheme.grauHell
                    }

                    Label {
                        anchors.centerIn: parent
                        font.pixelSize: 20
                        color: bilder.folder === "file://" + modelData.pfad
                               ? AppTheme.weiss : AppTheme.schwarz
                        text: qsTr(modelData.name)
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: bilder.folder = "file://" + modelData.pfad
                    }
                }
            }
        }

        GridView {
            id: raster
            anchors.top: leiste.bottom
            anchors.bottom: parent.bottom
            width: parent.width
            cellWidth: Math.floor(width / 3)
            cellHeight: cellWidth
            clip: true
            cacheBuffer: 0

            model: FolderListModel {
                id: bilder
                folder: blatt.wurzel + "/DCIM"
                nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.JPG", "*.JPEG", "*.PNG"]
                showDirs: false
                showDotAndDotDot: false
                // Das Neueste zuerst: wer meldet, hat das Foto gerade
                // eben geschossen.
                sortField: FolderListModel.Time
                sortReversed: false
            }

            delegate: Item {
                width: raster.cellWidth
                height: raster.cellHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    color: AppTheme.grauHell
                }

                Image {
                    anchors.fill: parent
                    anchors.margins: 2
                    fillMode: Image.PreserveAspectCrop
                    clip: true
                    asynchronous: true
                    // Klein dekodieren -- ein volles Foto je Kachel
                    // bringt das N9 ins Schwitzen.
                    sourceSize.width: raster.cellWidth
                    sourceSize.height: raster.cellHeight
                    // filePath ist hier schon eine URL
                    // ("file:///home/user/..."), kein nackter Pfad --
                    // am Geraet nachgesehen. Ein vorangestelltes
                    // "file://" ergaebe "file://file:///..." und ein
                    // leeres Bild.
                    source: filePath
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        // Die API will einen Dateipfad (QImage::load),
                        // das Modell gibt eine URL -- also abschneiden.
                        var s = String(filePath)
                        blatt.picked(s.indexOf("file://") === 0
                                     ? s.substring(7) : s)
                        blatt.reject()
                    }
                }
            }
        }

        ScrollDecorator { flickableItem: raster }

        Label {
            anchors.centerIn: parent
            width: parent.width - 48
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: AppTheme.grau
            visible: raster.count === 0
            text: qsTr("In diesem Ordner liegen keine Bilder")
        }
    }
}
