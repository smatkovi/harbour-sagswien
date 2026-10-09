import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: qsTr("Sag's Wien")
                description: qsTr("Fassung %1").arg(Qt.application.version)
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                text: qsTr("Ein eigener Client für den Meldungsdienst der "
                           + "Stadt Wien. Weder von der Stadt Wien noch vom "
                           + "Magistrat herausgegeben oder unterstützt.")
            }

            SectionHeader { text: qsTr("Woher die Daten kommen") }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
                text: qsTr("Meldungen: stp.wien.gv.at\n"
                           + "Adressen: data.wien.gv.at (OGD)\n"
                           + "Karten: basemap.at / Stadt Wien, CC BY 4.0")
            }

            SectionHeader { text: qsTr("Lizenz") }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
                text: qsTr("GNU GPL, Version 3 oder später.\n"
                           + "github.com/smatkovi/harbour-sagswien")
            }
        }

        VerticalScrollDecorator { }
    }
}
