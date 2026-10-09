import QtQuick 1.1
import com.nokia.meego 1.0

Page {
    id: page
    tools: reportTools

    property variant summary: ({})

    // Die volle Meldung, sobald sie da ist -- aber nur, wenn sie auch die
    // ist, die hier gezeigt wird (der Nutzer kann schneller sein als das
    // Netz und zwei Seiten tief stehen).
    property variant full: (Api.report && Api.report.meldungId === summary.meldungId)
                           ? Api.report : summary

    Header {
        id: header
        text: Format.statusName(page.full.status)
        subText: Format.categories(page.full)
    }

    Flickable {
        id: rolle
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        width: parent.width
        clip: true
        contentWidth: width
        contentHeight: spalte.height + 24

        Column {
            id: spalte
            width: parent.width
            spacing: 12

            Repeater {
                model: Format.imageIds(page.full)

                Item {
                    width: spalte.width
                    height: width * 3 / 4

                    Rectangle {
                        anchors.fill: parent
                        color: AppTheme.grauHell
                    }

                    Image {
                        id: foto
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        source: Images.photo(modelData, 640, Images.revision)
                    }

                    BusyIndicator {
                        anchors.centerIn: parent
                        running: foto.source === "" || foto.status === Image.Loading
                        visible: running
                    }
                }
            }

            Label {
                x: 16
                width: parent.width - 32
                wrapMode: Text.WordWrap
                font.pixelSize: 24
                color: AppTheme.schwarz
                text: page.full.meldungsText ? page.full.meldungsText
                                             : qsTr("(kein Text)")
            }

            Detail { label: qsTr("Ort"); value: Format.address(page.full) }
            Detail { label: qsTr("Gemeldet"); value: Format.when(page.full.tsMeldung) }
            Detail { label: qsTr("Entfernung"); value: Format.distance(page.full.abstand) }
            Detail {
                label: qsTr("Zustimmungen")
                value: page.full.anzahlLikes ? String(page.full.anzahlLikes) : "0"
            }

            Label {
                x: 16
                width: parent.width - 32
                font.pixelSize: 20
                color: AppTheme.grau
                visible: kommentare.count > 0
                text: qsTr("Kommentare")
            }

            Repeater {
                id: kommentare
                model: page.full.kommentare ? page.full.kommentare : []

                Column {
                    x: 16
                    width: spalte.width - 32
                    spacing: 2

                    Label {
                        width: parent.width
                        font.pixelSize: 16
                        color: AppTheme.rotDunkel
                        text: (modelData.istRedaktion ? qsTr("Stadt Wien")
                                                      : qsTr("Meldende Person"))
                              + " · " + Format.when(modelData.erzeugtAm)
                    }

                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        font.pixelSize: 20
                        color: AppTheme.schwarz
                        text: modelData.kommentarText ? modelData.kommentarText : ""
                    }

                    Item { width: 1; height: 8 }
                }
            }
        }
    }

    ScrollDecorator { flickableItem: rolle }

    ToolBarLayout {
        id: reportTools

        ToolIcon {
            platformIconId: "toolbar-back"
            onClicked: pageStack.pop()
        }
        ToolIcon {
            platformIconId: "toolbar-refresh"
            onClicked: Api.fetchReport(page.summary.meldungId)
        }
        ToolIcon {
            platformIconId: "toolbar-view-menu"
            visible: page.full.adresse !== undefined && page.full.adresse !== null
            onClicked: pageStack.push(Qt.resolvedUrl("MapPage.qml"),
                                      { focusReport: page.full })
        }
    }
}
