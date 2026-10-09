import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"
import "cover"

// Die gemeinsamen Texte stehen nicht hier, sondern in C++ (Format):
// eine nachgeladene Seite ist eine eigene Komponente und sieht die
// Kennung dieses Fensters nicht, und die MeeGo-Oberflaeche braucht
// dieselben Texte noch einmal.
ApplicationWindow {
    initialPage: Component { MainPage { } }
    cover: Component { CoverPage { } }
    allowedOrientations: defaultAllowedOrientations
}
