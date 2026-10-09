import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    // Die Zeile aus der Liste: sie steht sofort da, waehrend die volle
    // Meldung noch geholt wird. Ohne sie waere die Seite beim Aufschlagen
    // leer.
    property var summary: ({})

    // Die volle Meldung, sobald sie da ist -- aber nur, wenn sie auch die
    // ist, die hier gezeigt wird (der Nutzer kann schneller sein als das
    // Netz und zwei Seiten tief stehen).
    readonly property var full: (Api.report && Api.report.meldungId
                                 === summary.meldungId) ? Api.report : summary

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        PullDownMenu {
            MenuItem {
                text: qsTr("Auf der Karte zeigen")
                visible: page.full.adresse && page.full.adresse.latitude
                onClicked: pageStack.push(Qt.resolvedUrl("MapPage.qml"),
                                          { focusReport: page.full })
            }
            MenuItem {
                text: qsTr("Neu laden")
                onClicked: Api.fetchReport(page.summary.meldungId)
            }
        }

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: Format.statusName(page.full.status)
                description: Format.categories(page.full)
            }

            // Die Bilder. Breite 640 reicht fuer den Bildschirm und ist
            // ein Bruchteil des Vollbildes.
            Repeater {
                model: Format.imageIds(page.full)

                Item {
                    width: column.width
                    height: width * 3 / 4

                    Rectangle {
                        anchors.fill: parent
                        color: Theme.rgba(Theme.highlightBackgroundColor, 0.1)
                    }

                    Image {
                        id: photo
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        source: Images.photo(modelData, 640, Images.revision)
                    }

                    BusyIndicator {
                        anchors.centerIn: parent
                        running: photo.source === ""
                                 || photo.status === Image.Loading
                    }
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                text: page.full.meldungsText ? page.full.meldungsText
                                             : qsTr("(kein Text)")
            }

            DetailItem {
                label: qsTr("Ort")
                value: Format.address(page.full)
                visible: value !== ""
            }

            DetailItem {
                label: qsTr("Gemeldet")
                value: Format.when(page.full.tsMeldung)
                visible: value !== ""
            }

            DetailItem {
                label: qsTr("Entfernung")
                value: Format.distance(page.full.abstand)
                visible: value !== ""
            }

            DetailItem {
                label: qsTr("Zustimmungen")
                value: page.full.anzahlLikes ? String(page.full.anzahlLikes) : "0"
            }

            SectionHeader {
                text: qsTr("Kommentare")
                visible: kommentare.count > 0
            }

            Repeater {
                id: kommentare
                model: page.full.kommentare ? page.full.kommentare : []

                Column {
                    x: Theme.horizontalPageMargin
                    width: column.width - 2 * Theme.horizontalPageMargin
                    // Kein bottomPadding: das gibt es erst ab QtQuick 2.6,
                    // und unter 2.0 faellt damit die ganze Komponente aus.
                    spacing: Theme.paddingSmall / 2

                    Label {
                        width: parent.width
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryHighlightColor
                        text: (modelData.istRedaktion
                               ? qsTr("Stadt Wien") : qsTr("Meldende Person"))
                              + " · " + Format.when(modelData.erzeugtAm)
                    }

                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        font.pixelSize: Theme.fontSizeSmall
                        text: modelData.kommentarText ? modelData.kommentarText : ""
                    }

                    Item { width: 1; height: Theme.paddingMedium }
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                visible: page.full.provider !== undefined
                         && page.full.provider !== null
                         && page.full.provider !== ""
                text: qsTr("Übernommen von %1").arg(String(page.full.provider))
            }
        }

        VerticalScrollDecorator { }
    }

    BusyIndicator {
        anchors.centerIn: parent
        size: BusyIndicatorSize.Medium
        running: Api.busy && page.full === page.summary
    }
}
