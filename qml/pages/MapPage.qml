import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

Page {
    id: page

    // Entweder einen Ort waehlen (aus der neuen Meldung heraus) ...
    property bool pickMode: false
    // ... oder eine bestimmte Meldung zeigen.
    property var focusReport: null

    SilicaFlickable {
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: Images.satellite ? qsTr("Stadtplan") : qsTr("Luftbild")
                onClicked: Images.satellite = !Images.satellite
            }
            MenuItem {
                text: qsTr("Zum eigenen Standort")
                visible: Api.hasPosition
                onClicked: karte.goTo(Api.latitude, Api.longitude)
            }
            MenuItem {
                text: qsTr("Diesen Ort übernehmen")
                visible: page.pickMode
                onClicked: {
                    Api.setPosition(karte.centerLat, karte.centerLon)
                    pageStack.pop()
                }
            }
        }

        TileMap {
            id: karte
            anchors.fill: parent
            showPin: true
            pinLat: centerLat
            pinLon: centerLon
        }

        // Die Fadenkreuzmitte ist der Stecknadelkopf -- im Wahlmodus ist
        // das, was uebernommen wird, also immer die Bildmitte.
        Column {
            anchors.right: parent.right
            anchors.rightMargin: Theme.paddingLarge
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.paddingMedium

            IconButton {
                icon.source: "image://theme/icon-m-add"
                onClicked: karte.zoomIn()
            }
            IconButton {
                icon.source: "image://theme/icon-m-remove"
                onClicked: karte.zoomOut()
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: hinweis.height + 2 * Theme.paddingMedium
            color: Theme.rgba(Theme.highlightDimmerColor, 0.85)

            Label {
                id: hinweis
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                text: page.pickMode
                      ? qsTr("Karte schieben, dann oben „Diesen Ort übernehmen“")
                      : qsTr("Karten: basemap.at / Stadt Wien (CC BY 4.0)")
            }
        }
    }

    Component.onCompleted: {
        if (focusReport && focusReport.adresse) {
            karte.goTo(focusReport.adresse.latitude, focusReport.adresse.longitude)
            karte.pinLat = focusReport.adresse.latitude
            karte.pinLon = focusReport.adresse.longitude
        } else if (Api.hasPosition) {
            karte.goTo(Api.latitude, Api.longitude)
        }
    }
}
