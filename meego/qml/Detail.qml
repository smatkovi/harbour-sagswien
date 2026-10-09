import QtQuick 1.1
import com.nokia.meego 1.0

// Eine Zeile "Bezeichnung — Wert", wie sie die Detailseiten brauchen.
// Leere Werte verschwinden ganz; eine Zeile mit nichts dahinter ist
// schlechter als keine Zeile.
Item {
    property string label: ""
    property string value: ""

    width: parent.width
    height: value.length ? zeile.height : 0
    visible: value.length > 0

    Row {
        id: zeile
        x: 16
        width: parent.width - 32
        spacing: 8

        Label {
            width: (parent.width - 8) * 0.4
            font.pixelSize: 20
            color: AppTheme.grau
            elide: Text.ElideRight
            text: label
        }

        Label {
            width: (parent.width - 8) * 0.6
            font.pixelSize: 20
            color: AppTheme.schwarz
            wrapMode: Text.WordWrap
            text: value
        }
    }
}
