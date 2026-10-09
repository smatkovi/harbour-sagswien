#include <QGuiApplication>
#include <QQmlContext>
#include <QQuickView>
#include <QScopedPointer>

#include <sailfishapp.h>

#include "api.h"
#include "farben.h"
#include "format.h"
#include "images.h"
#include "locator.h"
#include "settings.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> application(SailfishApp::application(argc, argv));
    // Muss zur Kennung im [X-Sailjail]-Block der Startdatei passen, sonst
    // gibt der Sandkasten der App bei jedem Start aus dem Symbol einen
    // anderen, leeren Speicher -- und die Geraetekennung ist weg.
    application->setOrganizationName("harbour-sagswien");
    application->setApplicationName("harbour-sagswien");

    Settings settings;
    Api api(&settings);
    Images images(&settings);
    Locator locator;
    Format format;
    Farben farben;

    // Der Ortungsempfaenger meldet den ersten brauchbaren Fix an die API,
    // die daraus die Adresse holt.
    QObject::connect(&locator, SIGNAL(fixed(double,double)),
                     &api, SLOT(setPosition(double,double)));

    QScopedPointer<QQuickView> view(SailfishApp::createView());
    QQmlContext *context = view->rootContext();
    // Kontext-Eigenschaften statt angemeldeter Typen: es darf genau eine
    // Geraetekennung und genau einen Ortungsempfaenger geben.
    context->setContextProperty("Api", &api);
    context->setContextProperty("Images", &images);
    context->setContextProperty("Locator", &locator);
    context->setContextProperty("Settings", &settings);
    context->setContextProperty("Format", &format);
    // AppTheme, nicht Theme: com.nokia.meego verdeckt den Namen.
    context->setContextProperty("AppTheme", &farben);

    view->setSource(SailfishApp::pathTo("qml/harbour-sagswien.qml"));
    view->show();

    api.start();

    return application->exec();
}
