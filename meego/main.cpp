// Die MeeGo-Harmattan-Fassung: derselbe Kern aus src/ hinter einer
// com.nokia.meego-Oberflaeche, gestartet wie jede Harmattan-Qt-Quick-App.
//
// Unterschiede zum Sailfish-main, alle von Qt 4.7 erzwungen:
//   * QApplication und QDeclarativeView statt QGuiApplication/QQuickView
//   * die QML liegt in /opt/harbour-sagswien/qml
//   * das Fenster wird bildschirmfuellend gezeigt; Harmattan hat fuer
//     Anwendungen ohnehin keinen Fensterrahmen
//
// Und einer, der nicht von Qt kommt: der Kontextname "Theme" ist unter
// com.nokia.meego belegt, die eigene Farbtafel heisst deshalb "AppTheme".
#include <QApplication>
#include <QDeclarativeContext>
#include <QDeclarativeView>
#include <QDir>
#include <QFileInfo>
#include <QLocale>
#include <QTranslator>

#include "api.h"
#include "farben.h"
#include "format.h"
#include "images.h"
#include "locator.h"
#include "settings.h"

namespace
{
QString qmlFile()
{
    // Aus dem Baubaum laufen zu koennen ist das, was der QML-Pruefer und
    // ein schneller Versuch ueber ssh brauchen; der installierte Pfad
    // gewinnt, wenn er da ist.
    const QString installed = "/opt/harbour-sagswien/qml/main.qml";
    if (QFileInfo(installed).exists())
        return installed;
    return QDir(QCoreApplication::applicationDirPath()).filePath("qml/main.qml");
}
}

int main(int argc, char *argv[])
{
    QApplication application(argc, argv);
    application.setOrganizationName("harbour-sagswien");
    application.setApplicationName("harbour-sagswien");

    QTranslator translator;
    if (translator.load("harbour-sagswien-" + QLocale::system().name(),
                        "/opt/harbour-sagswien/translations"))
        application.installTranslator(&translator);

    Settings settings;
    Api api(&settings);
    Images images(&settings);
    Locator locator;
    Format format;
    Farben farben;

    QObject::connect(&locator, SIGNAL(fixed(double,double)),
                     &api, SLOT(setPosition(double,double)));

    QDeclarativeView view;
    QDeclarativeContext *context = view.rootContext();
    context->setContextProperty("Api", &api);
    context->setContextProperty("Images", &images);
    context->setContextProperty("Locator", &locator);
    context->setContextProperty("Settings", &settings);
    context->setContextProperty("Format", &format);
    // AppTheme, nicht Theme: com.nokia.meego verdeckt den Namen.
    context->setContextProperty("AppTheme", &farben);

    view.setResizeMode(QDeclarativeView::SizeRootObjectToView);
    view.setSource(QUrl::fromLocalFile(qmlFile()));
    view.showFullScreen();

    api.start();

    return application.exec();
}
