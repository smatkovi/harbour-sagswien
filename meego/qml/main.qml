import QtQuick 1.1
import com.nokia.meego 1.0
import com.nokia.extras 1.0   // InfoBanner

PageStackWindow {
    id: appWindow

    initialPage: MainPage { }
    showStatusBar: true
    showToolBar: true

    // Das Symbol der App ist weiss auf Rot; der helle Grund der
    // Standard-Apps passt dazu besser als der dunkle. theme.inverted ist
    // auf Harmattan global und wirkt bis in die Plattformhuelle.
    Component.onCompleted: theme.inverted = false

    InfoBanner {
        id: banner
        timerShowTime: 5000
    }

    function showMessage(text) {
        banner.text = text
        banner.show()
    }

    Connections {
        target: Api
        onReportSubmitted: appWindow.showMessage(qsTr("Meldung abgeschickt."))
        onLastErrorChanged: {
            if (Api.lastError !== "")
                appWindow.showMessage(Api.lastError)
        }
    }
}
