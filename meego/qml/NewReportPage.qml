import QtQuick 1.1
import com.nokia.meego 1.0

// Eine Meldung aufgeben.
//
// Hier liegt die einzige Stelle der App, die beim Dienst etwas anlegt --
// und es gibt keinen Testserver. Jede abgeschickte Meldung ist eine echte
// Beschwerde beim Magistrat und bindet Arbeitszeit von Menschen. Deshalb
// steht vor dem Senden eine ausdrueckliche Frage.
Page {
    id: page
    tools: neuTools

    property variant chosen: []
    property variant photos: []

    function bereit() {
        return text.text.length >= 10 && chosen.length > 0 && Api.hasPosition
    }

    Header { id: header; text: qsTr("Neue Meldung") }

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
                text: qsTr("Worum geht es?")
            }

            Repeater {
                model: Api.categories

                Item {
                    width: spalte.width
                    height: 72

                    CheckBox {
                        id: haken
                        x: 16
                        anchors.verticalCenter: parent.verticalCenter
                        checked: page.chosen.indexOf(modelData.kategorieId) >= 0
                        onClicked: {
                            var liste = []
                            for (var i = 0; i < page.chosen.length; ++i)
                                liste.push(page.chosen[i])
                            var at = liste.indexOf(modelData.kategorieId)
                            if (at >= 0)
                                liste.splice(at, 1)
                            else
                                liste.push(modelData.kategorieId)
                            page.chosen = liste
                        }
                    }

                    Column {
                        x: 80
                        width: parent.width - 96
                        anchors.verticalCenter: parent.verticalCenter

                        Label {
                            width: parent.width
                            elide: Text.ElideRight
                            font.pixelSize: 22
                            color: AppTheme.schwarz
                            text: modelData.bezeichnung
                        }
                        Label {
                            width: parent.width
                            elide: Text.ElideRight
                            font.pixelSize: 16
                            color: AppTheme.grau
                            visible: text.length > 0
                            text: modelData.untertitel ? modelData.untertitel : ""
                        }
                    }
                }
            }

            Label {
                x: 16
                font.pixelSize: 20
                color: AppTheme.grau
                text: qsTr("Beschreibung")
            }

            TextArea {
                id: text
                x: 16
                width: parent.width - 32
                height: 160
                placeholderText: qsTr("Was ist wo kaputt oder auffällig?")
            }

            Label {
                x: 16
                font.pixelSize: 20
                color: AppTheme.grau
                text: qsTr("Ort")
            }

            Label {
                x: 16
                width: parent.width - 32
                wrapMode: Text.WordWrap
                font.pixelSize: 22
                color: Api.hasPosition ? AppTheme.schwarz : AppTheme.rotDunkel
                text: Api.hasPosition
                      ? (Api.address ? Api.address
                                     : Api.latitude.toFixed(5) + ", "
                                       + Api.longitude.toFixed(5))
                      : (Locator.searching ? qsTr("Suche den Standort …")
                                           : qsTr("Kein Standort — Adresse eintippen"))
            }

            Row {
                x: 16
                width: parent.width - 32
                spacing: 8

                TextField {
                    id: adresse
                    width: parent.width - 140
                    placeholderText: qsTr("z. B. Sturzgasse 6A")
                }

                Button {
                    width: 132
                    text: qsTr("Suchen")
                    onClicked: {
                        Api.lookupAddress(adresse.text)
                        adresse.closeSoftwareInputPanel()
                    }
                }
            }

            Button {
                x: 16
                width: parent.width - 32
                text: qsTr("Auf der Karte wählen")
                onClicked: pageStack.push(Qt.resolvedUrl("MapPage.qml"),
                                          { pickMode: true })
            }

            Label {
                x: 16
                font.pixelSize: 20
                color: AppTheme.grau
                text: qsTr("Fotos")
            }

            Repeater {
                model: page.photos

                Item {
                    width: spalte.width
                    height: 56

                    Label {
                        x: 16
                        width: parent.width - 32
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideLeft
                        font.pixelSize: 18
                        color: AppTheme.schwarz
                        text: "✕  " + String(modelData).split("/").pop()
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            var liste = []
                            for (var i = 0; i < page.photos.length; ++i)
                                if (i !== index)
                                    liste.push(page.photos[i])
                            page.photos = liste
                        }
                    }
                }
            }

            Button {
                x: 16
                width: parent.width - 32
                text: qsTr("Foto aus der Galerie")
                enabled: bildwahl.status === Loader.Ready
                opacity: enabled ? 1.0 : 0.4
                onClicked: bildwahl.item.open()
            }

            Label {
                x: 16
                width: parent.width - 32
                wrapMode: Text.WordWrap
                font.pixelSize: 16
                color: AppTheme.rotDunkel
                visible: bildwahl.status === Loader.Error
                text: qsTr("Der Bildwähler lässt sich nicht öffnen. "
                           + "Melden geht trotzdem, nur ohne Foto.")
            }

            Label {
                x: 16
                width: parent.width - 32
                wrapMode: Text.WordWrap
                font.pixelSize: 16
                color: AppTheme.grau
                text: qsTr("Die Meldung geht an den Magistrat der Stadt Wien "
                           + "und wird dort von Menschen gelesen. Bitte nur "
                           + "echte Anliegen schicken.")
            }
        }
    }

    ScrollDecorator { flickableItem: rolle }

    // Ueber einen Loader, nicht unmittelbar: faellt der Bildwaehler aus
    // welchem Grund auch immer aus, soll **nur der Fotoknopf**
    // verschwinden -- nicht diese ganze Seite, und damit das Melden
    // ueberhaupt. Ein Fehler bleibt dann im Loader stecken.
    Loader {
        id: bildwahl
        source: "PhotoPicker.qml"
    }

    Connections {
        target: bildwahl.item
        onPicked: {
            var liste = []
            for (var i = 0; i < page.photos.length; ++i)
                liste.push(page.photos[i])
            liste.push(datei)
            page.photos = liste
        }
    }

    QueryDialog {
        id: frage
        titleText: qsTr("Wirklich melden?")
        message: qsTr("Die Meldung geht jetzt an die Stadt Wien und kann "
                      + "nicht zurückgenommen werden.")
        acceptButtonText: qsTr("Melden")
        rejectButtonText: qsTr("Abbrechen")
        onAccepted: {
            Api.submitReport(text.text, page.chosen, page.photos)
            pageStack.pop()
        }
    }

    ToolBarLayout {
        id: neuTools

        ToolIcon {
            platformIconId: "toolbar-back"
            onClicked: pageStack.pop()
        }
        ToolIcon {
            platformIconId: "toolbar-done"
            enabled: page.bereit()
            opacity: enabled ? 1.0 : 0.4
            onClicked: frage.open()
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active && !Api.hasPosition)
            Locator.start()
    }
}
