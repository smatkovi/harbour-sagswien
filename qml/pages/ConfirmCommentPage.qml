import QtQuick 2.0
import Sailfish.Silica 1.0

// Zwischen dem Knopf und dem Dienst steht eine Frage.
//
// Es gibt keinen Testserver: der Kommentar steht danach oeffentlich an
// einer fremden Meldung und laesst sich von hier aus nicht mehr
// zuruecknehmen. Das soll man einmal gelesen haben.
Dialog {
    id: dialog

    property string meldungId: ""
    property string kommentar: ""
    property var feld: null

    onAccepted: {
        Api.submitComment(meldungId, kommentar)
        if (feld)
            feld.text = ""
    }

    Column {
        width: parent.width
        spacing: Theme.paddingMedium

        DialogHeader {
            acceptText: qsTr("Abschicken")
            cancelText: qsTr("Zurück")
            title: qsTr("Kommentar")
        }

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2 * Theme.horizontalPageMargin
            wrapMode: Text.WordWrap
            text: dialog.kommentar
        }

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2 * Theme.horizontalPageMargin
            wrapMode: Text.WordWrap
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
            text: qsTr("Der Kommentar steht danach öffentlich an dieser "
                       + "Meldung und kann von hier nicht zurückgenommen "
                       + "werden.")
        }
    }
}
