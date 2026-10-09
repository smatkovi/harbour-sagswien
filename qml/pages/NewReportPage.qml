import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0

// Eine Meldung aufgeben.
//
// Hier liegt die einzige Stelle der App, die beim Dienst etwas anlegt --
// und es gibt keinen Testserver. Jede abgeschickte Meldung ist eine echte
// Beschwerde beim Magistrat und bindet Arbeitszeit von Menschen. Deshalb
// steht vor dem Senden eine ausdrueckliche Frage, und der Knopf heisst,
// was er tut.
Dialog {
    id: dialog

    property string text: ""
    property var chosenCategories: []
    property var photos: []

    canAccept: text.trim().length >= 10 && chosenCategories.length > 0
               && Api.hasPosition
    acceptDestinationAction: PageStackAction.Pop

    onAccepted: Api.submitReport(text, chosenCategories, photos)

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            DialogHeader {
                acceptText: qsTr("Wirklich melden")
                cancelText: qsTr("Abbrechen")
                title: qsTr("Neue Meldung")
            }

            SectionHeader { text: qsTr("Worum geht es?") }

            Repeater {
                model: Api.categories

                TextSwitch {
                    width: column.width
                    text: modelData.bezeichnung
                    description: modelData.untertitel ? modelData.untertitel : ""
                    automaticCheck: false
                    checked: dialog.chosenCategories.indexOf(modelData.kategorieId) >= 0
                    onClicked: {
                        var list = dialog.chosenCategories.slice()
                        var at = list.indexOf(modelData.kategorieId)
                        if (at >= 0)
                            list.splice(at, 1)
                        else
                            list.push(modelData.kategorieId)
                        dialog.chosenCategories = list
                    }
                }
            }

            SectionHeader { text: qsTr("Beschreibung") }

            TextArea {
                width: column.width
                placeholderText: qsTr("Was ist wo kaputt oder auffällig?")
                label: qsTr("Mindestens zehn Zeichen")
                text: dialog.text
                onTextChanged: dialog.text = text
            }

            SectionHeader { text: qsTr("Ort") }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                color: Api.hasPosition ? Theme.primaryColor : Theme.errorColor
                text: Api.hasPosition
                      ? (Api.address ? Api.address
                                     : Api.latitude.toFixed(5) + ", "
                                       + Api.longitude.toFixed(5))
                      : (Locator.searching ? qsTr("Suche den Standort …")
                                           : qsTr("Kein Standort — Adresse eintippen"))
            }

            SearchField {
                width: column.width
                placeholderText: qsTr("Adresse, z. B. Sturzgasse 6A")
                EnterKey.onClicked: {
                    Api.lookupAddress(text)
                    focus = false
                }
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Auf der Karte wählen")
                onClicked: pageStack.push(Qt.resolvedUrl("MapPage.qml"),
                                          { pickMode: true })
            }

            SectionHeader { text: qsTr("Fotos") }

            Repeater {
                model: dialog.photos

                ListItem {
                    width: column.width
                    contentHeight: Theme.itemSizeSmall

                    Label {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        anchors.verticalCenter: parent.verticalCenter
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeSmall
                        text: modelData.split("/").pop()
                    }

                    onClicked: {
                        var list = dialog.photos.slice()
                        list.splice(index, 1)
                        dialog.photos = list
                    }
                }
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Foto hinzufügen")
                onClicked: pageStack.push(bildwahl)
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: qsTr("Die Meldung geht an den Magistrat der Stadt Wien "
                           + "und wird dort von Menschen gelesen. Bitte nur "
                           + "echte Anliegen schicken.")
            }
        }

        VerticalScrollDecorator { }
    }

    Component {
        id: bildwahl
        ImagePickerPage {
            onSelectedContentPropertiesChanged: {
                var list = dialog.photos.slice()
                list.push(selectedContentProperties.filePath)
                dialog.photos = list
            }
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active && !Api.hasPosition)
            Locator.start()
    }
}
