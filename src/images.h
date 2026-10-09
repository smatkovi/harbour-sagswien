#ifndef IMAGES_H
#define IMAGES_H

#include <QHash>
#include <QObject>
#include <QSet>
#include <QString>

class Http;
class Settings;

// Alle Bilder, die von aussen kommen: die Fotos der Meldungen und die
// Kartenkacheln. Beide landen auf Platte und werden von dort an QML
// gegeben.
//
// Warum nicht einfach die Adresse in ein Image schreiben: auf Harmattan
// kommt Qt 4.7 an keinen der beiden Server heran (TLS 1.0 gegen Server, die
// 1.2 verlangen -- doc/BEFUND.md, Abschnitt 9; der Kachelserver antwortet
// auf http mit 301 auf https, es gibt also keinen Umweg). Sie gehen
// deshalb durch denselben Holer wie alles andere. Auf Sailfish ginge es
// direkt, aber der Zwischenspeicher ist auch dort richtig: eine Karte holt
// beim Schieben sonst dieselben Kacheln wieder und wieder.
//
// Verwendung in QML -- `revision` steht im Aufruf, damit die Bindung neu
// rechnet, sobald ein Bild angekommen ist:
//
//     Image { source: Images.photo(imageId, 400, Images.revision) }
//     Image { source: Images.tile(z, x, y, Images.revision) }
class Images : public QObject
{
    Q_OBJECT
    // Zaehlt bei jedem fertigen Bild hoch; dient nur als Anstoss fuer die
    // Bindungen in QML.
    Q_PROPERTY(int revision READ revision NOTIFY revisionChanged)
    // true = Luftbild, false = Stadtplan.
    Q_PROPERTY(bool satellite READ satellite WRITE setSatellite NOTIFY satelliteChanged)

public:
    // Settings ist dabei, damit die Kartenart nur an einer Stelle
    // steht: die Einstellungsseite schaltet sie, der Zwischenspeicher
    // liest sie, und sie ueberlebt den Neustart.
    explicit Images(Settings *settings, QObject *parent = 0);

    int revision() const { return m_revision; }
    bool satellite() const;
    void setSatellite(bool satellite);

    // Das Foto einer Meldung. breite 0 heisst voll -- auf einem Telefon
    // will man das nie (480 KB gegen 24 KB bei 400).
    // Der letzte Wert wird nicht benutzt; er steht nur da, damit die
    // Bindung von `revision` abhaengt.
    Q_INVOKABLE QString photo(const QString &imageId, int width,
                              int revision = 0);

    // Eine Kartenkachel von basemap.at / Stadt Wien.
    Q_INVOKABLE QString tile(int z, int x, int y, int revision = 0);

    Q_INVOKABLE void clearCache();

signals:
    void revisionChanged();
    void satelliteChanged();

private slots:
    void replyFinished(int tag, int status, const QByteArray &body,
                       const QString &error);

private:
    // Gemeinsamer Weg fuer Foto und Kachel: liegt die Datei schon da, gib
    // sie zurueck; sonst hol sie und gib fuer jetzt nichts zurueck.
    QString cached(const QString &file, const QString &url);

    Settings *m_settings;
    Http *m_http;
    QString m_directory;
    int m_nextTag;
    int m_revision;
    QHash<int, QString> m_pending;  // Marke -> Dateiname
    QSet<QString> m_running;        // schon unterwegs, nicht zweimal holen
    QSet<QString> m_failed;         // nicht endlos erneut versuchen
};

#endif
