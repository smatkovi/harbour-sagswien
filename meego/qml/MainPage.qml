import QtQuick 1.1
import com.nokia.meego 1.0

Page {
    id: page
    tools: mainTools

    function listName(typ) {
        if (typ === 0) return qsTr("Alle Meldungen")
        if (typ === 1) return qsTr("In der Nähe")
        return qsTr("Meine Meldungen")
    }

    Header {
        id: header
        text: qsTr("Sag's Wien")
        subText: page.listName(Api.listType)
    }

    ListView {
        id: list
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        width: parent.width
        clip: true
        model: Api.reports

        delegate: Item {
            width: list.width
            height: Math.max(78, zeilen.height + 20)

            property variant report: modelData
            property string thumbId: report.images && report.images.length
                                     ? report.images[0].imageId : ""

            Rectangle {
                anchors.fill: parent
                color: druck.pressed ? AppTheme.grauHell : "transparent"
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: AppTheme.grauHell
            }

            Image {
                id: vorschau
                x: 12
                anchors.verticalCenter: parent.verticalCenter
                width: visible ? 64 : 0
                height: 64
                fillMode: Image.PreserveAspectCrop
                clip: true
                asynchronous: true
                visible: thumbId !== ""
                source: thumbId ? Images.photo(thumbId, 240, Images.revision) : ""
            }

            Column {
                id: zeilen
                x: vorschau.visible ? 88 : 12
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - x - 12
                spacing: 2

                Label {
                    width: parent.width
                    elide: Text.ElideRight
                    font.pixelSize: 18
                    color: Format.statusColor(report.status)
                    text: Format.statusName(report.status)
                          + " · " + Format.categories(report)
                }

                Label {
                    width: parent.width
                    maximumLineCount: 2
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    font.pixelSize: 22
                    color: AppTheme.schwarz
                    text: report.meldungsText ? report.meldungsText
                                              : qsTr("(kein Text)")
                }

                Label {
                    width: parent.width
                    elide: Text.ElideRight
                    font.pixelSize: 16
                    color: AppTheme.grau
                    text: {
                        var teile = [Format.when(report.tsMeldung)]
                        var wo = Format.address(report)
                        if (wo) teile.push(wo)
                        var weit = Format.distance(report.abstand)
                        if (weit) teile.push(weit)
                        return teile.join(" · ")
                    }
                }
            }

            MouseArea {
                id: druck
                anchors.fill: parent
                onClicked: {
                    Api.fetchReport(report.meldungId)
                    pageStack.push(Qt.resolvedUrl("ReportPage.qml"),
                                   { summary: report })
                }
            }
        }
    }

    ScrollDecorator { flickableItem: list }

    Label {
        anchors.centerIn: parent
        width: parent.width - 48
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        color: AppTheme.grau
        visible: !Api.busy && Api.reports.length === 0
        text: Api.ready ? qsTr("Keine Meldungen")
                        : qsTr("Melde das Gerät beim Dienst an …")
    }

    BusyIndicator {
        anchors.centerIn: parent
        platformStyle: BusyIndicatorStyle { size: "large" }
        running: Api.busy && Api.reports.length === 0
        visible: running
    }

    ToolBarLayout {
        id: mainTools

        ToolIcon {
            platformIconId: "toolbar-add"
            onClicked: pageStack.push(Qt.resolvedUrl("NewReportPage.qml"))
        }
        ToolIcon {
            platformIconId: "toolbar-refresh"
            onClicked: Api.refresh()
        }
        ToolIcon {
            platformIconId: "toolbar-view-menu"
            onClicked: hauptmenue.open()
        }
    }

    Menu {
        id: hauptmenue
        MenuLayout {
            MenuItem {
                text: qsTr("Alle Meldungen")
                onClicked: Api.fetchReports(0)
            }
            MenuItem {
                text: Api.hasPosition ? qsTr("In der Nähe")
                                      : qsTr("In der Nähe (kein Standort)")
                enabled: Api.hasPosition
                onClicked: Api.fetchReports(1)
            }
            MenuItem {
                text: qsTr("Meine Meldungen")
                onClicked: Api.fetchReports(2)
            }
            MenuItem {
                text: qsTr("Karte")
                onClicked: pageStack.push(Qt.resolvedUrl("MapPage.qml"))
            }
            MenuItem {
                text: qsTr("Einstellungen")
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
            }
            MenuItem {
                text: qsTr("Über")
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }
        }
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
