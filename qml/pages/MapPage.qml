import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

// Die Karte liegt **nicht** in einer SilicaFlickable.
//
// Sie wuerde sonst mit dem Pulley-Menue um denselben Zug streiten: die
// Karte fuellt die ganze Seite, und sobald ein Schieben die Schwelle
// ueberschreitet, zieht die Flickable das Menue auf statt die Karte zu
// bewegen. TileMap haelt den Zug zwar selbst fest (preventStealing), aber
// dann waere das Pulley gar nicht mehr erreichbar -- also gibt es hier
// keins, und die Befehle stehen als Knoepfe auf der Leiste unten.
Page {
    id: page

    // Entweder einen Ort waehlen (aus der neuen Meldung heraus) ...
    property bool pickMode: false
    // ... oder eine bestimmte Meldung zeigen.
    property var focusReport: null

    TileMap {
        id: karte
        anchors.fill: parent
        showPin: true
        pinLat: centerLat
        pinLon: centerLon
    }

    // Zoom rechts, wo der Daumen hinkommt.
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
        id: leiste
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: inhalt.height + 2 * Theme.paddingMedium
        color: Theme.rgba(Theme.highlightDimmerColor, 0.9)

        Column {
            id: inhalt
            x: Theme.horizontalPageMargin
            width: parent.width - 2 * Theme.horizontalPageMargin
            y: Theme.paddingMedium
            spacing: Theme.paddingSmall

            Label {
                width: parent.width
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: page.pickMode
                      ? qsTr("Karte schieben, bis der Punkt stimmt")
                      : qsTr("Karten: basemap.at / Stadt Wien (CC BY 4.0)")
            }

            Flow {
                width: parent.width
                spacing: Theme.paddingMedium

                Button {
                    text: Images.satellite ? qsTr("Stadtplan") : qsTr("Luftbild")
                    onClicked: Images.satellite = !Images.satellite
                }

                Button {
                    text: qsTr("Mein Standort")
                    visible: Api.hasPosition
                    onClicked: karte.goTo(Api.latitude, Api.longitude)
                }

                Button {
                    text: qsTr("Ort übernehmen")
                    visible: page.pickMode
                    onClicked: {
                        Api.setPosition(karte.centerLat, karte.centerLon)
                        pageStack.pop()
                    }
                }
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
