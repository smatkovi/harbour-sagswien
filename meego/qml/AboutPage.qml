import QtQuick 1.1
import com.nokia.meego 1.0

Page {
    id: page
    tools: ueberTools

    Header { id: header; text: qsTr("Sag's Wien") }

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
                width: parent.width - 32
                font.pixelSize: 20
                color: AppTheme.grau
                text: qsTr("Fassung %1").arg(Qt.application.version)
            }

            Label {
                x: 16
                width: parent.width - 32
                wrapMode: Text.WordWrap
                font.pixelSize: 22
                color: AppTheme.schwarz
                text: qsTr("Ein eigener Client für den Meldungsdienst der "
                           + "Stadt Wien. Weder von der Stadt Wien noch vom "
                           + "Magistrat herausgegeben oder unterstützt.")
            }

            Label {
                x: 16
                width: parent.width - 32
                wrapMode: Text.WordWrap
                font.pixelSize: 18
                color: AppTheme.grau
                text: qsTr("Meldungen: stp.wien.gv.at\n"
                           + "Adressen: data.wien.gv.at (OGD)\n"
                           + "Karten: basemap.at / Stadt Wien, CC BY 4.0\n\n"
                           + "GNU GPL, Version 3 oder später.\n"
                           + "github.com/smatkovi/harbour-sagswien")
            }
        }
    }

    ScrollDecorator { flickableItem: rolle }

    ToolBarLayout {
        id: ueberTools
        ToolIcon {
            platformIconId: "toolbar-back"
            onClicked: pageStack.pop()
        }
    }
}
