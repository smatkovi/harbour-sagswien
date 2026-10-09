#ifndef LOCATOR_H
#define LOCATOR_H

#include <QObject>
#include <QTimer>

#if QT_VERSION >= 0x050000
#include <QGeoPositionInfo>
#include <QGeoPositionInfoSource>
#else
// Harmattan traegt die Ortung in QtMobility, in eigenem Namensraum. Die
// Klassennamen und Signale sind dieselben -- deshalb uebersetzt alles
// darunter fuer beide Fassungen unveraendert.
#include <QGeoPositionInfo>
#include <QGeoPositionInfoSource>
QTM_USE_NAMESPACE
#endif

// Wo das Telefon steht. Mehr braucht diese App nicht: eine Meldung hat
// genau einen Ort, und der wird einmal bestimmt, nicht fortlaufend
// mitgeschrieben.
//
// Auf dem N9/N950 gibt der Sitzungsbus com.nokia.positioningd.client nur
// einem Prozess heraus, der die Faehigkeit `Location` traegt -- die steht
// im _aegis-Manifest des Pakets. Ohne sie bleibt die Position ewig
// ungueltig, ohne jede Fehlermeldung.
class Locator : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool valid READ valid NOTIFY positionChanged)
    Q_PROPERTY(bool searching READ searching NOTIFY searchingChanged)
    Q_PROPERTY(double latitude READ latitude NOTIFY positionChanged)
    Q_PROPERTY(double longitude READ longitude NOTIFY positionChanged)
    Q_PROPERTY(double accuracy READ accuracy NOTIFY positionChanged)
    Q_PROPERTY(bool available READ available CONSTANT)

public:
    explicit Locator(QObject *parent = 0);

    bool valid() const { return m_valid; }
    bool searching() const { return m_searching; }
    double latitude() const { return m_latitude; }
    double longitude() const { return m_longitude; }
    double accuracy() const { return m_accuracy; }
    bool available() const { return m_source != 0; }

public slots:
    void start();
    void stop();
    // Den Ort von Hand setzen -- aus der Karte oder aus der Adresssuche.
    void setManual(double latitude, double longitude);

signals:
    void positionChanged();
    void searchingChanged();
    // Nur beim ersten brauchbaren Fix, damit die Seite nicht bei jedem
    // Zucken neu laedt.
    void fixed(double latitude, double longitude);

private slots:
    void positionUpdated(const QGeoPositionInfo &info);
    void giveUp();

private:
    void setSearching(bool searching);

    QGeoPositionInfoSource *m_source;
    QTimer m_timeout;
    bool m_valid;
    bool m_searching;
    bool m_announced;
    double m_latitude;
    double m_longitude;
    double m_accuracy;
};

#endif
