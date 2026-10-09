#ifndef API_H
#define API_H

#include <QDateTime>
#include <QHash>
#include <QObject>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

class Http;
class Settings;

// Der Client fuer den Meldungsdienst der Stadt Wien,
// https://stp.wien.gv.at/sagswienWeb2025/
//
// Woher die Kenntnis stammt: aus der Android-App 4.0.8 ausgelesen und am
// Dienst selbst nachgemessen -- doc/BEFUND.md fuehrt jeden Punkt und sagt,
// was belegt und was vermutet ist. Die drei Dinge, die man beim Mitlesen
// des Codes wissen muss:
//
//  1. Es gibt keine Anmeldung. Die `geraetInfoId` ist die Sitzung: einmal
//     `PUT Geraet`, Kennung behalten, danach traegt sie jeder Koerper.
//     Es gibt keinen authToken (der Server schickt null).
//  2. **Aufzaehlungen sind nackte Zahlen.** Die App deklariert ihre
//     Serialnamen als "0"/"1"/"2" und schickt damit JSON-Zeichenketten;
//     der Server ist ASP.NET Core und antwortet darauf mit HTTP 400
//     ("The JSON value could not be converted to ...OSPlatformen").
//     Also 0, nicht "0" -- fuer osPlatform, status, sortierung, type.
//  3. Die Antwort nennt die Kategorienliste **`Kategorien`** mit grossem K,
//     nicht `kategorien` wie das Modell der App. Wer klein liest, sieht
//     nie eine Kategorie.
class Api : public QObject
{
    Q_OBJECT
    // Erst wenn eine Geraetekennung da ist, nimmt der Dienst ueberhaupt
    // etwas an -- ohne sie antwortet Meldung/Filtered mit HTTP 500.
    Q_PROPERTY(bool ready READ ready NOTIFY readyChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    Q_PROPERTY(QVariantList categories READ categories NOTIFY categoriesChanged)
    Q_PROPERTY(QVariantList reports READ reports NOTIFY reportsChanged)
    Q_PROPERTY(QVariantMap report READ report NOTIFY reportChanged)
    Q_PROPERTY(QString nickname READ nickname NOTIFY readyChanged)
    // Was gerade in die Liste geladen wurde: 0 alle, 1 Naehe, 2 eigene.
    Q_PROPERTY(int listType READ listType NOTIFY reportsChanged)
    Q_PROPERTY(bool hasPosition READ hasPosition NOTIFY positionChanged)
    Q_PROPERTY(double latitude READ latitude NOTIFY positionChanged)
    Q_PROPERTY(double longitude READ longitude NOTIFY positionChanged)
    Q_PROPERTY(QString address READ address NOTIFY positionChanged)

public:
    // Die Listen, die die Oberflaeche anbietet.
    enum ListType { AllReports = 0, NearbyReports = 1, OwnReports = 2 };

    explicit Api(Settings *settings, QObject *parent = 0);

    bool ready() const { return !m_deviceId.isEmpty(); }
    bool busy() const { return m_open > 0; }
    QString lastError() const { return m_lastError; }
    QVariantList categories() const { return m_categories; }
    QVariantList reports() const { return m_reports; }
    QVariantMap report() const { return m_report; }
    QString nickname() const;
    int listType() const { return m_listType; }
    bool hasPosition() const { return m_hasPosition; }
    double latitude() const { return m_latitude; }
    double longitude() const { return m_longitude; }
    QString address() const { return m_address; }

public slots:
    // Nimmt die gespeicherte Kennung wieder auf und registriert das Geraet,
    // wenn noch keine da ist. Danach die Kategorien.
    void start();

    void fetchCategories();
    // typ nach ListType. Die Naheliste braucht eine Position.
    void fetchReports(int typ);
    void refresh();
    // Holt die ganze Meldung mit Kommentaren und allen Bildern.
    void fetchReport(const QString &meldungId);

    // Vom Ortungsempfaenger. Loest die Adressauflösung mit aus.
    void setPosition(double latitude, double longitude);
    // Adresse eintippen statt orten: GetAddressInfo der Stadt Wien.
    void lookupAddress(const QString &text);

    // Die Bildadresse zu einer Bildkennung. breite 0 heisst voll --
    // auf einem Telefon will man das nie (480 KB gegen 24 KB bei 400).
    QString imageUrl(const QString &imageId, int width) const;

    // Eine Meldung abschicken.
    //
    // ACHTUNG: Es gibt keinen Testserver. Jede abgeschickte Meldung ist
    // eine echte Beschwerde beim Magistrat und bindet Arbeitszeit von
    // Menschen. Diese Methode gehoert hinter eine ausdrueckliche
    // Bestaetigung des Nutzers und wird beim Entwickeln nicht aufgerufen;
    // geprueft wird sie ueber reportBody(), das denselben Koerper baut,
    // ohne ihn zu senden.
    void submitReport(const QString &text, const QStringList &categoryIds,
                      const QStringList &photoFiles);

    // Derselbe Koerper, nur zurueckgegeben statt geschickt -- so laesst
    // sich der Anlege-Weg gegen die Form der Original-App pruefen, ohne
    // den Dienst anzufassen. Siehe tests/.
    QByteArray reportBody(const QString &text, const QStringList &categoryIds,
                          const QStringList &photoFiles) const;

public:
    // Das Bauen des Meldungskoerpers, herausgezogen und ohne Zustand.
    //
    // Warum frei und nicht in der Methode: es gibt keinen Testserver, und
    // `PUT Meldung` darf beim Entwickeln nicht abgeschickt werden. Diese
    // Funktion ist also die **einzige** Stelle, an der sich der Anlege-Weg
    // ueberhaupt pruefen laesst -- und das geht nur, wenn man sie ohne
    // Netz, ohne Ortung und ohne Einstellungen aufrufen kann.
    // tests/bodytest.cpp tut genau das.
    static QByteArray buildReport(const QString &deviceId,
                                  const QString &appVersion,
                                  const QString &text,
                                  const QStringList &categoryIds,
                                  const QStringList &photoFiles,
                                  double latitude, double longitude,
                                  const QVariantMap &addressFields,
                                  const QDateTime &now);

signals:
    void readyChanged();
    void busyChanged();
    void lastErrorChanged();
    void categoriesChanged();
    void reportsChanged();
    void reportChanged();
    void positionChanged();
    // Nach einer wirklich abgeschickten Meldung.
    void reportSubmitted(const QString &meldungId);

private slots:
    void replyFinished(int tag, int status, const QByteArray &body,
                       const QString &error);

private:
    enum Kind {
        RegisterDevice,
        Categories,
        Reports,
        OneReport,
        ReverseGeocode,
        ForwardGeocode,
        SubmitReport
    };

    int send(Kind kind, const QString &verb, const QString &path,
             const QVariant &body);
    void setError(const QString &text);
    void setBusy(int delta);
    void registerDevice();
    QVariantMap deviceStamp() const;
    // Beide Adressdienste der Stadt (ReverseGeocode und GetAddressInfo)
    // antworten mit demselben GeoJSON und denselben Eigenschaftsnamen --
    // und die passen eins zu eins auf das AdressDTO der Meldung: ACD, SCD
    // und Bezirk sind dort eigene Felder (nachgemessen: die SCD "04798"
    // einer echten Meldung ist genau die der Sturzgasse 6A).
    void applyAddress(const QVariantMap &properties);

    Settings *m_settings;
    Http *m_http;
    QHash<int, int> m_kinds;        // Marke -> Kind
    QHash<int, QString> m_subjects; // Marke -> worum es ging (Meldungskennung)
    int m_nextTag;
    int m_open;

    QString m_deviceId;
    QString m_lastError;
    QVariantList m_categories;
    QVariantList m_reports;
    QVariantMap m_report;
    int m_listType;

    bool m_hasPosition;
    double m_latitude;
    double m_longitude;
    QString m_address;
    QVariantMap m_addressFields;
};

#endif
