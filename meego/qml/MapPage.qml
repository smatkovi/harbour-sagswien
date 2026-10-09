import QtQuick 1.1
import com.nokia.meego 1.0

Page {
    id: page
    tools: kartenTools

    property bool pickMode: false
    property variant focusReport: null

    TileMap {
        id: karte
        anchors.fill: parent
        showPin: true
        pinLat: centerLat
        pinLon: centerLon
    }

    Column {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        Button {
            width: 64
            height: 64
            text: "+"
            onClicked: karte.zoomIn()
        }
        Button {
            width: 64
            height: 64
            text: "−"
            onClicked: karte.zoomOut()
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: hinweis.height + 16
        color: AppTheme.weiss
        opacity: 0.85

        Label {
            id: hinweis
            x: 12
            width: parent.width - 24
            anchors.verticalCenter: parent.verticalCenter
            wrapMode: Text.WordWrap
            font.pixelSize: 16
            color: AppTheme.schwarz
            text: page.pickMode
                  ? qsTr("Karte schieben, dann der Haken oben")
                  : qsTr("Karten: basemap.at / Stadt Wien (CC BY 4.0)")
        }
    }

    ToolBarLayout {
        id: kartenTools

        ToolIcon {
            platformIconId: "toolbar-back"
            onClicked: pageStack.pop()
        }
        ToolIcon {
            platformIconId: "toolbar-refresh"
            visible: Api.hasPosition
            onClicked: karte.goTo(Api.latitude, Api.longitude)
        }
        ToolIcon {
            platformIconId: "toolbar-done"
            visible: page.pickMode
            onClicked: {
                Api.setPosition(karte.centerLat, karte.centerLon)
                pageStack.pop()
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
