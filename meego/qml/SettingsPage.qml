import QtQuick 1.1
import com.nokia.meego 1.0

Page {
    id: page
    tools: einstellTools

    Header { id: header; text: qsTr("Einstellungen") }

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

            Label {
                x: 16
                font.pixelSize: 20
                color: AppTheme.grau
                text: qsTr("Liste beim Start")
            }

            // ButtonRow braucht auf Harmattan den checked-Zustand an den
            // Knoepfen selbst -- ein selectedIndex gibt es hier nicht.
            ButtonRow {
                x: 16
                width: parent.width - 32

                Button {
                    text: qsTr("Alle")
                    checked: Settings.startList === 0
                    onClicked: Settings.startList = 0
                }
                Button {
                    text: qsTr("Nähe")
                    checked: Settings.startList === 1
                    onClicked: Settings.startList = 1
                }
                Button {
                    text: qsTr("Eigene")
                    checked: Settings.startList === 2
                    onClicked: Settings.startList = 2
                }
            }

            Label {
                x: 16
                font.pixelSize: 20
                color: AppTheme.grau
                text: qsTr("Umkreis für „In der Nähe“: %1")
                      .arg(Settings.searchRadius < 1000
                           ? qsTr("%1 m").arg(Settings.searchRadius)
                           : qsTr("%1 km").arg((Settings.searchRadius / 1000).toFixed(1)))
            }

            Slider {
                x: 16
                width: parent.width - 32
                minimumValue: 250
                maximumValue: 5000
                stepSize: 250
                value: Settings.searchRadius
                onValueChanged: Settings.searchRadius = value
            }

            Item {
                width: parent.width
                height: 72

                // com.nokia.meegos Switch hat **kein** clicked-Signal --
                // nur checked. Ein onClicked daran laesst die ganze Seite
                // nicht mehr laden ("Cannot assign to non-existent
                // property"), und zwar erst auf dem Geraet: der Pruefer
                // auf dem Baurechner hat die Bibliothek nicht und blendet
                // genau diese Fehlerklasse aus.
                Switch {
                    id: luft
                    x: 16
                    anchors.verticalCenter: parent.verticalCenter
                    checked: Settings.satelliteMap
                    onCheckedChanged: Images.satellite = checked
                }

                Label {
                    x: 110
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 22
                    color: AppTheme.schwarz
                    text: qsTr("Luftbild statt Stadtplan")
                }
            }

            Detail { label: qsTr("Angemeldet als")
                     value: Api.nickname ? Api.nickname : qsTr("noch nicht") }

            Label {
                x: 16
                width: parent.width - 32
                wrapMode: Text.WordWrap
                font.pixelSize: 16
                color: AppTheme.grau
                text: qsTr("Der Dienst kennt kein Passwort: die Gerätekennung "
                           + "ist die Anmeldung. Wird sie gelöscht, sind die "
                           + "eigenen Meldungen nicht mehr als eigene zu sehen.")
            }

            Button {
                x: 16
                width: parent.width - 32
                text: qsTr("Bildspeicher leeren")
                onClicked: Images.clearCache()
            }
        }
    }

    ScrollDecorator { flickableItem: rolle }

    ToolBarLayout {
        id: einstellTools
        ToolIcon {
            platformIconId: "toolbar-back"
            onClicked: pageStack.pop()
        }
    }
}
