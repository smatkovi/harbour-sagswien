import QtQuick 1.1
import com.nokia.meego 1.0

// Der Seitentitel, wie ihn die Standard-Apps tragen: ein Band in der
// Hausfarbe mit dem Namen darin.
Rectangle {
    property alias text: label.text
    property alias subText: unter.text

    width: parent.width
    height: unter.text.length ? 92 : 72
    color: AppTheme.rot

    Column {
        anchors.verticalCenter: parent.verticalCenter
        x: 16
        width: parent.width - 32

        Label {
            id: label
            width: parent.width
            elide: Text.ElideRight
            font.pixelSize: 28
            color: AppTheme.weiss
        }

        Label {
            id: unter
            width: parent.width
            elide: Text.ElideRight
            font.pixelSize: 18
            color: AppTheme.weiss
            opacity: 0.85
            visible: text.length > 0
        }
    }
}
