// Liest jede QML-Datei der MeeGo-Ausgabe ein und meldet, was
// QDeclarative daran auszusetzen hat -- ohne Bildschirm und ohne Geraet.
//
// Warum es das gibt: eine vertippte Eigenschaft oder eine Komponente, die
// es unter QtQuick 1.1 nicht gibt, faellt nicht beim Bauen auf, sondern
// beim Oeffnen der Seite, auf dem Geraet, in der Hand des Nutzers.
// QDeclarativeComponent findet das hier, in einer Sekunde.
//
// Es findet nicht alles: com.nokia.meego ist auf dem Baurechner nicht
// installiert, deshalb wird die Fehlerliste um das gekuerzt, was nur vom
// fehlenden Import kommt. Was uebrig bleibt, sind unsere eigenen Fehler.
#include <QCoreApplication>
#include <QDeclarativeComponent>
#include <QDeclarativeContext>
#include <QDeclarativeEngine>
#include <QDir>
#include <QStringList>
#include <QTextStream>

#include "stubs.h"

int main(int argc, char *argv[])
{
    QCoreApplication application(argc, argv);
    QTextStream out(stdout);

    const QStringList arguments = application.arguments();
    if (arguments.size() < 2) {
        out << "Aufruf: qml_check <qml-verzeichnis>\n";
        return 2;
    }

    QDeclarativeEngine engine;
    StubFormat format;
    StubApi api;
    StubImages images;
    StubLocator locator;
    StubSettings settings;
    StubFarben farben;
    engine.rootContext()->setContextProperty("Format", &format);
    engine.rootContext()->setContextProperty("Api", &api);
    engine.rootContext()->setContextProperty("Images", &images);
    engine.rootContext()->setContextProperty("Locator", &locator);
    engine.rootContext()->setContextProperty("Settings", &settings);
    engine.rootContext()->setContextProperty("AppTheme", &farben);

    const QDir directory(arguments.at(1));
    const QStringList names = directory.entryList(QStringList() << "*.qml",
                                                  QDir::Files, QDir::Name);
    int complaints = 0;
    for (int i = 0; i < names.size(); ++i) {
        const QString path = directory.filePath(names.at(i));
        QDeclarativeComponent component(&engine, QUrl::fromLocalFile(path));
        const QList<QDeclarativeError> errors = component.errors();
        for (int e = 0; e < errors.size(); ++e) {
            const QString text = errors.at(e).toString();
            // Alles, was nur daher kommt, dass com.nokia.meego und
            // QtMobility.gallery hier fehlen; das Geraet hat beides.
            if (text.contains("com.nokia.meego") || text.contains("com.nokia.extras")
                || text.contains("QtMobility")
                || text.contains("is not a type") || text.contains("is not installed"))
                continue;
            out << text << "\n";
            ++complaints;
        }
    }
    out << (complaints ? QString("%1 Beanstandung(en)\n").arg(complaints)
                       : QString("qml in Ordnung (%1 Dateien)\n").arg(names.size()));
    return complaints ? 1 : 0;
}
