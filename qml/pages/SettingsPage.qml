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

            PageHeader { title: qsTr("Einstellungen") }

            ComboBox {
                width: parent.width
                label: qsTr("Liste beim Start")
                currentIndex: Settings.startList
                menu: ContextMenu {
                    MenuItem { text: qsTr("Alle Meldungen") }
                    MenuItem { text: qsTr("In der Nähe") }
                    MenuItem { text: qsTr("Meine Meldungen") }
                }
                onCurrentIndexChanged: Settings.startList = currentIndex
            }

            Slider {
                width: parent.width
                label: qsTr("Umkreis für „In der Nähe“")
                minimumValue: 250
                maximumValue: 5000
                stepSize: 250
                value: Settings.searchRadius
                valueText: value < 1000 ? qsTr("%1 m").arg(value)
                                        : qsTr("%1 km").arg((value / 1000).toFixed(1))
                onValueChanged: Settings.searchRadius = value
            }

            TextSwitch {
                text: qsTr("Luftbild statt Stadtplan")
                checked: Settings.satelliteMap
                onClicked: Images.satellite = !Images.satellite
            }

            SectionHeader { text: qsTr("Gerät") }

            DetailItem {
                label: qsTr("Angemeldet als")
                value: Api.nickname ? Api.nickname : qsTr("noch nicht")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: qsTr("Der Dienst kennt kein Passwort: die Gerätekennung "
                           + "ist die Anmeldung. Wird sie gelöscht, sind die "
                           + "eigenen Meldungen nicht mehr als eigene zu sehen.")
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Bildspeicher leeren")
                onClicked: Images.clearCache()
            }
        }

        VerticalScrollDecorator { }
    }
}
