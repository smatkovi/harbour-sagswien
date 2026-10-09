#ifndef FORMAT_H
#define FORMAT_H

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariant>
#include <QVariantMap>

// Die Texte, die beide Oberflaechen gleich schreiben muessen.
//
// Das steht in C++ und nicht als JavaScript-Helfer in der QML, aus zwei
// Gruenden: es gibt zwei getrennte QML-Baeume (Silica und com.nokia.meego),
// und eine Funktion im Wurzelelement des einen ist im anderen nicht zu
// sehen -- Kennungen sind in QML auf ihre Komponente beschraenkt, eine
// nachgeladene Seite sieht das `id` der Anwendung nicht. Dazu formatiert
// Qt 4.7s JavaScript Datumswerte anders als Qt 5.
class Format : public QObject
{
    Q_OBJECT
public:
    explicit Format(QObject *parent = 0) : QObject(parent) {}

    // Die Statuszahlen des Dienstes. Belegt aus der Original-App
    // (oc4.java:59-66): 0 Neu, 2 In Bearbeitung, 4 Erledigt, 8 Geloescht.
    Q_INVOKABLE QString statusName(int status) const;
    // Als Zeichenkette, damit sie in beiden QML-Dialekten direkt in eine
    // color-Eigenschaft passt.
    Q_INVOKABLE QString statusColor(int status) const;

    // "2026-10-09T13:35:41+02:00" -> "9.10.2026, 13:35"
    Q_INVOKABLE QString when(const QString &isoStamp) const;

    // Die Kategorien einer Meldung, mit Komma verbunden.
    //
    // Hier sitzt eine Falle des Dienstes: die Liste heisst in der Antwort
    // **`Kategorien`** mit grossem K, nicht `kategorien` wie im Modell der
    // App. Wer nur klein nachsieht, bekommt nie eine Kategorie zu sehen.
    Q_INVOKABLE QString categories(const QVariantMap &report) const;

    // "1150 Sturzgasse 6A"
    Q_INVOKABLE QString address(const QVariantMap &report) const;

    // Entfernung in Metern oder Kilometern, oder leer.
    Q_INVOKABLE QString distance(const QVariant &metres) const;

    // Die Bildkennungen einer Meldung, in der Reihenfolge der Antwort.
    Q_INVOKABLE QStringList imageIds(const QVariantMap &report) const;
};

#endif
