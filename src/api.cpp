#include "api.h"

#include "http.h"
#include "json.h"
#include "settings.h"

#include <QBuffer>
#include <QDateTime>
#include <QFile>
#include <QFileInfo>
#include <QImage>
#include <QLocale>
#include <QUrl>
#include <QUuid>

namespace
{
// Die Grundadresse steht im Binaer der App als Retrofit-Basis
// ("RetrofitSagsWien", iv.java). Der Schraegstrich am Ende gehoert dazu.
const char *BaseUrl = "https://stp.wien.gv.at/sagswienWeb2025/";

// Die Adressdienste der Stadt Wien (Open Government Data). Dieselben, die
// die Original-App nimmt.
const char *OgdUrl = "https://data.wien.gv.at/daten/OGDAddressService.svc/";

// Die Fassung, die wir dem Dienst nennen. Sie steht in jedem Koerper als
// appVersion, so wie es die App tut.
const char *AppVersion = APP_VERSION;

const char *NullGuid = "00000000-0000-0000-0000-000000000000";

// Laengster Rand eines mitgeschickten Fotos. Die Bilder der Meldungen
// kommen vom Dienst mit 400 Pixel Breite daher; mehr als 1280 hochzuladen
// kostet auf dem N9 nur Zeit und Mobilfunk.
const int MaxPhotoEdge = 1280;
const int PhotoQuality = 82;

// Der Dienst schreibt seine Zeitstempel mit Zeitzone
// ("2026-10-09T13:35:41+02:00"); genauso schicken wir sie zurueck.
QString stamp(const QDateTime &when)
{
    // Qt 4.7 schreibt keinen Zonenversatz, der Dienst will ihn aber
    // ("2026-10-09T13:35:41+02:00"). Also selbst ausrechnen: die naiv
    // genommene Ortszeit minus die naiv genommene UTC-Zeit.
    const QDateTime utc = when.toUTC();
    const int minutes = QDateTime(utc.date(), utc.time())
            .secsTo(QDateTime(when.date(), when.time())) / 60;
    const int absolute = minutes < 0 ? -minutes : minutes;
    return when.toString("yyyy-MM-ddThh:mm:ss")
            + (minutes < 0 ? QChar('-') : QChar('+'))
            + QString("%1:%2").arg(absolute / 60, 2, 10, QChar('0'))
                              .arg(absolute % 60, 2, 10, QChar('0'));
}

// Ein Foto so verkleinern und kodieren, wie es in rawImage gehoert.
// Rueckgabe leer, wenn die Datei nicht zu lesen war.
QString encodePhoto(const QString &file, int *width, int *height)
{
    QImage image;
    if (!image.load(file))
        return QString();
    if (image.width() > MaxPhotoEdge || image.height() > MaxPhotoEdge) {
        image = image.scaled(MaxPhotoEdge, MaxPhotoEdge, Qt::KeepAspectRatio,
                             Qt::SmoothTransformation);
    }
    QByteArray raw;
    QBuffer buffer(&raw);
    buffer.open(QIODevice::WriteOnly);
    if (!image.save(&buffer, "JPEG", PhotoQuality))
        return QString();
    if (width)
        *width = image.width();
    if (height)
        *height = image.height();
    return QString::fromLatin1(raw.toBase64());
}
}

Api::Api(Settings *settings, QObject *parent) :
    QObject(parent),
    m_settings(settings),
#if QT_VERSION >= 0x050000
    m_http(new NetworkHttp(this)),
#else
    m_http(new ProcessHttp(this)),
#endif
    m_nextTag(1),
    m_open(0),
    m_listType(NearbyReports),
    m_hasPosition(false),
    m_latitude(0),
    m_longitude(0)
{
    connect(m_http, SIGNAL(finished(int,int,QByteArray,QString)),
            this, SLOT(replyFinished(int,int,QByteArray,QString)));
}

QString Api::nickname() const
{
    return m_settings->nickname();
}

void Api::setError(const QString &text)
{
    if (m_lastError == text)
        return;
    m_lastError = text;
    emit lastErrorChanged();
}

void Api::setBusy(int delta)
{
    const bool before = busy();
    m_open += delta;
    if (m_open < 0)
        m_open = 0;
    if (busy() != before)
        emit busyChanged();
}

int Api::send(Kind kind, const QString &verb, const QString &path,
              const QVariant &body)
{
    const int tag = m_nextTag++;
    m_kinds.insert(tag, int(kind));

    QStringList headers;
    headers << "Accept: application/json";
    QByteArray payload;
    if (body.isValid()) {
        payload = Json::serialise(body);
        headers << "Content-Type: application/json";
    }

    const bool absolute = path.startsWith("http");
    const QString url = absolute ? path : QString::fromLatin1(BaseUrl) + path;

    setBusy(1);
    m_http->request(tag, verb, url, payload, headers);
    return tag;
}

// Die Felder, die in jeden Koerper gehoeren: wer fragt und mit welcher
// Fassung. Ohne geraetInfoId antwortet der Dienst mit HTTP 500.
QVariantMap Api::deviceStamp() const
{
    QVariantMap map;
    map.insert("geraetInfoId", m_deviceId.isEmpty()
               ? QString::fromLatin1(NullGuid) : m_deviceId);
    map.insert("appVersion", QString::fromLatin1(AppVersion));
    return map;
}

void Api::start()
{
    m_deviceId = m_settings->deviceId();
    if (m_deviceId.isEmpty()) {
        registerDevice();
        return;
    }
    emit readyChanged();
    fetchCategories();
}

void Api::registerDevice()
{
    QVariantMap body;
    // Eine eigene, zufaellige Kennung. Der Dienst behaelt sie nicht (sie
    // kommt leer zurueck), aber die App schickt eine, also tun wir es auch.
    QString hardware = QUuid::createUuid().toString();
    hardware.remove('{');
    hardware.remove('}');
    body.insert("hardwareId", hardware);
    body.insert("isHardwareIdKnown", true);
    body.insert("cultureName", QLocale::system().name().replace('_', '-'));
    // OSPlatformen als **Zahl**. Als "0" gibt es HTTP 400, siehe api.h.
    body.insert("osPlatform", 0);
#if QT_VERSION >= 0x050000
    body.insert("model", "Sailfish OS");
#else
    body.insert("model", "MeeGo Harmattan");
#endif
    QVariantMap version;
    version.insert("major", 0);
    version.insert("minor", 1);
    version.insert("build", 0);
    version.insert("revision", 0);
    body.insert("osVersion", version);
    body.insert("appVersion", QString::fromLatin1(AppVersion));

    send(RegisterDevice, "PUT", "Geraet", body);
}

void Api::fetchCategories()
{
    send(Categories, "GET", "Kategorie/All", QVariant());
}

void Api::fetchReports(int typ)
{
    if (!ready()) {
        // Ohne Kennung geht gar nichts -- erst registrieren, die Liste
        // holt dann start() nach.
        registerDevice();
        return;
    }
    if (typ == NearbyReports && !m_hasPosition) {
        setError(tr("Ohne Standort keine Meldungen in der Nähe."));
        return;
    }

    QVariantMap body = deviceStamp();
    body.insert("maximaleAnzahl", 50);
    body.insert("maximaleTage", 180);
    // SortierungType als Zahl: 0 ist die Vorgabe der App.
    body.insert("sortierung", 0);
    body.insert("unterdrueckeGeloeschteMeldungen", true);
    body.insert("unterdrueckeArchivierte", true);
    body.insert("excludeExternalProviderMessages", false);
    body.insert("adresseRequired", true);

    if (typ == OwnReports) {
        body.insert("eigeneMeldungen", true);
    } else if (typ == NearbyReports) {
        QVariantMap address = deviceStamp();
        address.insert("latitude", m_latitude);
        address.insert("longitude", m_longitude);
        body.insert("inNaeheAdresse", address);
        body.insert("distanz", m_settings->searchRadius());
    }

    m_listType = typ;
    const int tag = send(Reports, "POST", "Meldung/Filtered", body);
    Q_UNUSED(tag)
}

void Api::refresh()
{
    fetchReports(m_listType);
}

void Api::fetchReport(const QString &meldungId)
{
    if (!ready() || meldungId.isEmpty())
        return;
    QVariantMap body = deviceStamp();
    body.insert("meldungId", meldungId);
    // Pflichtfelder des Modells, damit der Deuter der Gegenseite nicht
    // stolpert: StatusTypen als Zahl, Zeitstempel als jetzt.
    body.insert("status", 0);
    body.insert("tsMeldung", stamp(QDateTime::currentDateTime()));
    const int tag = send(OneReport, "POST", "Meldung/GetById", body);
    m_subjects.insert(tag, meldungId);
}

void Api::setPosition(double latitude, double longitude)
{
    const bool first = !m_hasPosition;
    m_hasPosition = true;
    m_latitude = latitude;
    m_longitude = longitude;
    emit positionChanged();

    // Die Adresse zur Position -- die Meldung braucht sie, und der Nutzer
    // will lesen, wo er steht. crs=EPSG:4326, so wie die App fragt.
    const QString path = QString::fromLatin1(OgdUrl)
            + QString("ReverseGeocode?location=%1,%2&crs=EPSG:4326&type=A3:8012")
              .arg(longitude, 0, 'f', 6).arg(latitude, 0, 'f', 6);
    send(ReverseGeocode, "GET", path, QVariant());

    if (first && m_settings->startList() == NearbyReports && ready())
        fetchReports(NearbyReports);
}

void Api::lookupAddress(const QString &text)
{
    if (text.trimmed().isEmpty())
        return;
    const QString path = QString::fromLatin1(OgdUrl)
            + "GetAddressInfo?Address=" + QUrl::toPercentEncoding(text)
            + "&crs=EPSG:4326";
    send(ForwardGeocode, "GET", path, QVariant());
}

QString Api::imageUrl(const QString &imageId, int width) const
{
    if (imageId.isEmpty() || imageId == QString::fromLatin1(NullGuid))
        return QString();
    QString url = QString::fromLatin1(BaseUrl) + "images/BySize/" + imageId + "/";
    if (width > 0)
        url += QString::number(width);
    return url;
}

QByteArray Api::buildReport(const QString &deviceId, const QString &appVersion,
                            const QString &text, const QStringList &categoryIds,
                            const QStringList &photoFiles,
                            double latitude, double longitude,
                            const QVariantMap &addressFields,
                            const QDateTime &now)
{
    QVariantMap stempel;
    stempel.insert("geraetInfoId", deviceId);
    stempel.insert("appVersion", appVersion);

    QVariantMap body = stempel;
    // Eine neue Meldung traegt die Nullkennung; der Dienst setzt die echte.
    body.insert("meldungId", QString::fromLatin1(NullGuid));
    // StatusTypen als **Zahl**. Als "0" gaebe es HTTP 400, siehe api.h.
    body.insert("status", 0);
    body.insert("meldungsText", text);
    body.insert("tsMeldung", stamp(now));

    QVariantMap address = stempel;
    address.insert("latitude", latitude);
    address.insert("longitude", longitude);
    for (QVariantMap::const_iterator it = addressFields.constBegin();
         it != addressFields.constEnd(); ++it) {
        address.insert(it.key(), it.value());
    }
    body.insert("adresse", address);

    QVariantList ids;
    for (int i = 0; i < categoryIds.size(); ++i)
        ids.append(categoryIds.at(i));
    body.insert("kategorieIds", ids);

    QVariantList images;
    for (int i = 0; i < photoFiles.size(); ++i) {
        int width = 0;
        int height = 0;
        const QString raw = encodePhoto(photoFiles.at(i), &width, &height);
        if (raw.isEmpty())
            continue;
        QVariantMap image = stempel;
        image.insert("imageId", QString::fromLatin1(NullGuid));
        image.insert("rawImage", raw);
        image.insert("aufnahmedatum", stamp(now));
        image.insert("breite", width);
        image.insert("hoehe", height);
        image.insert("logischGeloescht", false);
        images.append(image);
    }
    body.insert("images", images);

    return Json::serialise(body);
}

QByteArray Api::reportBody(const QString &text, const QStringList &categoryIds,
                           const QStringList &photoFiles) const
{
    return buildReport(m_deviceId.isEmpty() ? QString::fromLatin1(NullGuid) : m_deviceId,
                       QString::fromLatin1(AppVersion), text, categoryIds,
                       photoFiles, m_latitude, m_longitude, m_addressFields,
                       QDateTime::currentDateTime());
}

void Api::submitReport(const QString &text, const QStringList &categoryIds,
                       const QStringList &photoFiles)
{
    if (!ready()) {
        setError(tr("Noch keine Gerätekennung — bitte neu starten."));
        return;
    }
    if (text.trimmed().isEmpty() || categoryIds.isEmpty()) {
        setError(tr("Text und Kategorie fehlen."));
        return;
    }
    if (!m_hasPosition) {
        setError(tr("Ohne Ort kann die Stadt nichts nachsehen."));
        return;
    }

    const int tag = m_nextTag++;
    m_kinds.insert(tag, int(SubmitReport));
    QStringList headers;
    headers << "Accept: application/json" << "Content-Type: application/json";
    setBusy(1);
    m_http->request(tag, "PUT", QString::fromLatin1(BaseUrl) + "Meldung",
                    reportBody(text, categoryIds, photoFiles), headers);
}

void Api::replyFinished(int tag, int status, const QByteArray &body,
                        const QString &error)
{
    setBusy(-1);
    const Kind kind = Kind(m_kinds.take(tag));
    const QString subject = m_subjects.take(tag);

    if (status == 0) {
        setError(error.isEmpty() ? tr("Keine Verbindung.") : error);
        return;
    }

    QString parseError;
    const QVariant answer = Json::parse(body, &parseError);

    if (status < 200 || status >= 300) {
        // ASP.NET Core nennt die kaputten Felder einzeln und im Klartext --
        // das ist genau die Meldung, die man sehen will. Nur die Beilage
        // "geraeteInfoDTO is required" ist irrefuehrend: sie kommt immer
        // mit, wenn die Bindung des Koerpers scheiterte.
        QString text = tr("Der Dienst antwortet mit %1.").arg(status);
        const QVariant fields = Json::value(answer, "errors");
        const QVariant direct = answer;
        const QVariantMap map = fields.isValid() ? fields.toMap() : direct.toMap();
        QStringList parts;
        for (QVariantMap::const_iterator it = map.constBegin();
             it != map.constEnd(); ++it) {
            if (it.key() == "geraeteInfoDTO")
                continue;
            parts << it.value().toStringList().join(" ");
        }
        if (!parts.isEmpty())
            text = parts.join("\n");
        setError(text);
        return;
    }

    setError(QString());

    switch (kind) {
    case RegisterDevice: {
        const QVariantMap map = answer.toMap();
        const QString id = map.value("geraetInfoId").toString();
        if (id.isEmpty() || id == QString::fromLatin1(NullGuid)) {
            setError(tr("Der Dienst gab keine Gerätekennung zurück."));
            return;
        }
        m_deviceId = id;
        m_settings->setDeviceId(id);
        m_settings->setProfileId(map.value("profileId").toString());
        const QVariantMap profile = map.value("profile").toMap();
        if (!profile.value("nickname").toString().isEmpty())
            m_settings->setNickname(profile.value("nickname").toString());
        emit readyChanged();
        fetchCategories();
        break;
    }
    case Categories: {
        m_categories = answer.toList();
        emit categoriesChanged();
        // Jetzt steht alles bereit, was die Startseite braucht.
        fetchReports(m_settings->startList());
        break;
    }
    case Reports: {
        m_reports = answer.toList();
        emit reportsChanged();
        break;
    }
    case OneReport: {
        m_report = answer.toMap();
        Q_UNUSED(subject)
        emit reportChanged();
        break;
    }
    case ReverseGeocode: {
        // GeoJSON der Stadt Wien: features[0].properties.
        applyAddress(Json::value(answer, "features/0/properties").toMap());
        break;
    }
    case ForwardGeocode: {
        const QVariantList list = Json::value(answer, "features").toList();
        if (list.isEmpty()) {
            setError(tr("Diese Adresse findet die Stadt nicht."));
            return;
        }
        const QVariantMap first = list.at(0).toMap();
        const QVariantList coords =
                Json::value(first, "geometry/coordinates").toList();
        if (coords.size() >= 2) {
            // GeoJSON zaehlt Laenge zuerst, dann Breite.
            m_hasPosition = true;
            m_longitude = coords.at(0).toDouble();
            m_latitude = coords.at(1).toDouble();
        }
        // Die Eigenschaften stehen schon in dieser Antwort -- kein zweiter
        // Gang zum Adressdienst.
        applyAddress(first.value("properties").toMap());
        break;
    }
    case SubmitReport: {
        const QVariantMap map = answer.toMap();
        emit reportSubmitted(map.value("meldungId").toString());
        refresh();
        break;
    }
    }

    if (!parseError.isEmpty() && !answer.isValid())
        setError(parseError);
}

void Api::applyAddress(const QVariantMap &properties)
{
    m_addressFields.clear();
    if (properties.isEmpty()) {
        emit positionChanged();
        return;
    }

    const QString strasse = properties.value("StreetName").toString();
    const QString nummer = properties.value("StreetNumber").toString();
    const QString plz = properties.value("PostalCode").toString();
    const QString ort = properties.value("Municipality").toString();
    const QString acd = properties.value("ACD").toString();
    const QString scd = properties.value("SCD").toString();
    const QString bezirk = properties.value("Bezirk").toString();
    QString ganz = properties.value("Adresse").toString();
    if (ganz.isEmpty())
        ganz = (strasse + " " + nummer).trimmed();

    if (!strasse.isEmpty())
        m_addressFields.insert("strasse", strasse);
    if (!nummer.isEmpty())
        m_addressFields.insert("hausnummer", nummer);
    // plz ist im Modell der Meldung eine Zahl, nicht eine Zeichenkette
    // (nachgemessen: "plz": 1150).
    if (!plz.isEmpty())
        m_addressFields.insert("plz", plz.toInt());
    m_addressFields.insert("ort", ort.isEmpty() ? QString("Wien") : ort);
    if (!acd.isEmpty())
        m_addressFields.insert("acd", acd);
    if (!scd.isEmpty())
        m_addressFields.insert("scd", scd);
    if (!bezirk.isEmpty())
        m_addressFields.insert("bezirk", bezirk);
    if (!ganz.isEmpty())
        m_addressFields.insert("adresse", ganz);

    m_address = ganz.isEmpty() ? ort : ganz;
    emit positionChanged();
}
