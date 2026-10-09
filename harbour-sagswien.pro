# Die Sailfish-Ausgabe. Die MeeGo-Ausgabe baut meego/build.sh aus
# demselben src/, mit eigenem main und eigener QML.

TARGET = harbour-sagswien

CONFIG += sailfishapp

QT += positioning network

# Die Fassung steht im Spec und kommt von dort; ohne sie faellt APP_VERSION
# auf einen Platzhalter zurueck, und der Dienst bekaeme ein leeres
# appVersion-Feld.
isEmpty(VERSION): VERSION = 0.0.0
DEFINES += APP_VERSION=\\\"$$VERSION\\\"

SOURCES += \
    src/harbour-sagswien.cpp \
    src/api.cpp \
    src/format.cpp \
    src/http.cpp \
    src/images.cpp \
    src/json.cpp \
    src/locator.cpp \
    src/settings.cpp

HEADERS += \
    src/api.h \
    src/farben.h \
    src/format.h \
    src/http.h \
    src/images.h \
    src/json.h \
    src/locator.h \
    src/settings.h

DISTFILES += \
    harbour-sagswien.desktop \
    rpm/harbour-sagswien.spec \
    rpm/harbour-sagswien.yaml \
    qml/harbour-sagswien.qml \
    qml/cover/CoverPage.qml \
    qml/components/TileMap.qml \
    qml/pages/MainPage.qml \
    qml/pages/ReportPage.qml \
    qml/pages/NewReportPage.qml \
    qml/pages/MapPage.qml \
    qml/pages/SettingsPage.qml \
    qml/pages/AboutPage.qml

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

CONFIG += sailfishapp_i18n
