import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    // 0 alle, 1 in der Naehe, 2 eigene -- dieselben Zahlen wie Api::ListType.
    property int listType: Api.listType

    function listName(typ) {
        switch (typ) {
        case 0: return qsTr("Alle Meldungen")
        case 1: return qsTr("In der Nähe")
        case 2: return qsTr("Meine Meldungen")
        }
        return ""
    }

    SilicaListView {
        id: view
        anchors.fill: parent
        model: Api.reports

        PullDownMenu {
            MenuItem {
                text: qsTr("Über Sag's Wien")
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }
            MenuItem {
                text: qsTr("Einstellungen")
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
            }
            MenuItem {
                text: qsTr("Karte")
                onClicked: pageStack.push(Qt.resolvedUrl("MapPage.qml"))
            }
            MenuItem {
                text: qsTr("Neue Meldung")
                onClicked: pageStack.push(Qt.resolvedUrl("NewReportPage.qml"))
            }
        }

        PushUpMenu {
            MenuItem {
                text: qsTr("Aktualisieren")
                onClicked: Api.refresh()
            }
        }

        header: Column {
            width: view.width

            PageHeader {
                title: page.listName(page.listType)
                description: Api.nickname
            }

            // Die drei Listen des Dienstes. "In der Nähe" braucht eine
            // Position; ohne Fix bleibt der Knopf grau statt ins Leere zu
            // laufen.
            ComboBox {
                width: parent.width
                label: qsTr("Liste")
                currentIndex: page.listType
                menu: ContextMenu {
                    MenuItem { text: qsTr("Alle Meldungen") }
                    MenuItem {
                        text: Api.hasPosition ? qsTr("In der Nähe")
                                              : qsTr("In der Nähe (kein Standort)")
                        enabled: Api.hasPosition
                    }
                    MenuItem { text: qsTr("Meine Meldungen") }
                }
                onCurrentIndexChanged: {
                    if (currentIndex !== Api.listType)
                        Api.fetchReports(currentIndex)
                }
            }

            Label {
                visible: Api.lastError !== ""
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                color: Theme.errorColor
                font.pixelSize: Theme.fontSizeSmall
                text: Api.lastError
            }

            Item { width: 1; height: Theme.paddingMedium }
        }

        delegate: ListItem {
            id: item
            contentHeight: row.height + 2 * Theme.paddingMedium

            property var report: modelData
            // Das erste Bild als Vorschau, 240 Pixel breit -- mehr braucht
            // die Zeile nicht, und das Volle waere 480 KB.
            property string thumbId: report.images && report.images.length
                                     ? report.images[0].imageId : ""

            Row {
                id: row
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                y: Theme.paddingMedium
                spacing: Theme.paddingMedium

                Rectangle {
                    width: Theme.itemSizeMedium
                    height: Theme.itemSizeMedium
                    color: Theme.rgba(Theme.highlightBackgroundColor, 0.1)
                    visible: item.thumbId !== ""

                    Image {
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        clip: true
                        asynchronous: true
                        source: item.thumbId
                                ? Images.photo(item.thumbId, 240, Images.revision)
                                : ""
                    }
                }

                Column {
                    width: parent.width - (item.thumbId !== ""
                           ? Theme.itemSizeMedium + Theme.paddingMedium : 0)
                    spacing: Theme.paddingSmall / 2

                    Label {
                        width: parent.width
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeSmall
                        color: Format.statusColor(item.report.status)
                        text: Format.statusName(item.report.status)
                              + " · " + Format.categories(item.report)
                    }

                    Label {
                        width: parent.width
                        maximumLineCount: 2
                        wrapMode: Text.WordWrap
                        elide: Text.ElideRight
                        color: item.highlighted ? Theme.highlightColor
                                                : Theme.primaryColor
                        text: item.report.meldungsText
                              ? item.report.meldungsText
                              : qsTr("(kein Text)")
                    }

                    Label {
                        width: parent.width
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        text: {
                            var parts = [Format.when(item.report.tsMeldung)]
                            var where = Format.address(item.report)
                            if (where)
                                parts.push(where)
                            var far = Format.distance(item.report.abstand)
                            if (far)
                                parts.push(far)
                            return parts.join(" · ")
                        }
                    }
                }
            }

            onClicked: {
                Api.fetchReport(report.meldungId)
                pageStack.push(Qt.resolvedUrl("ReportPage.qml"),
                               { summary: report })
            }
        }

        ViewPlaceholder {
            enabled: !Api.busy && Api.reports.length === 0
            text: Api.ready ? qsTr("Keine Meldungen")
                            : qsTr("Melde das Gerät beim Dienst an …")
            hintText: Api.ready
                      ? qsTr("Nach unten ziehen für eine neue Meldung")
                      : ""
        }

        VerticalScrollDecorator { }
    }

    BusyIndicator {
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: Api.busy && Api.reports.length === 0
    }

    // Die Ortung laeuft nur, solange die Liste offen ist -- ein Empfaenger,
    // der im Hintergrund weitersucht, ist auf dem N9 der schnellste Weg zu
    // einem leeren Akku.
    onStatusChanged: {
        if (status === PageStatus.Active && !Api.hasPosition)
            Locator.start()
        else if (status === PageStatus.Deactivating)
            Locator.stop()
    }
}
