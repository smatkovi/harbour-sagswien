#include "images.h"

#include "http.h"
#include "settings.h"

#include <QDir>
#include <QFile>
#include <QUrl>

#if QT_VERSION >= 0x050000
#include <QStandardPaths>
#else
#include <QDesktopServices>
#endif

namespace
{
const char *BaseUrl = "https://stp.wien.gv.at/sagswienWeb2025/";

// Die Rasterkacheln der Stadt Wien. Die Original-App zeichnet
// Vektorkacheln mit libmaplibre -- das gibt es auf keinem der beiden
// Zielsysteme, dieselbe Gegend liegt aber als 256er-Raster bereit.
// Lizenz: basemap.at / Stadt Wien, CC BY 4.0.
const char *TileMap = "https://mapsneu.wien.gv.at/basemap/geolandbasemap/"
                      "normal/google3857/%1/%2/%3.png";
const char *TileAerial = "https://mapsneu.wien.gv.at/basemap/bmaporthofoto30cm/"
                         "normal/google3857/%1/%2/%3.jpeg";

QString cacheRoot()
{
#if QT_VERSION >= 0x050000
    const QString base = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
#else
    const QString base = QDesktopServices::storageLocation(QDesktopServices::CacheLocation);
#endif
    return base + "/bilder";
}
}

Images::Images(Settings *settings, QObject *parent) :
    QObject(parent),
    m_settings(settings),
#if QT_VERSION >= 0x050000
    m_http(new NetworkHttp(this)),
#else
    m_http(new ProcessHttp(this)),
#endif
    m_directory(cacheRoot()),
    m_nextTag(1),
    m_revision(0)
{
    QDir().mkpath(m_directory);
    QDir().mkpath(m_directory + "/kacheln");
    connect(m_http, SIGNAL(finished(int,int,QByteArray,QString)),
            this, SLOT(replyFinished(int,int,QByteArray,QString)));
}

bool Images::satellite() const
{
    return m_settings->satelliteMap();
}

void Images::setSatellite(bool satellite)
{
    if (m_settings->satelliteMap() == satellite)
        return;
    m_settings->setSatelliteMap(satellite);
    emit satelliteChanged();
    // Die Kacheln liegen je Art unter eigenem Namen -- die Karte rechnet
    // ihre Bindungen durch diesen Anstoss neu.
    ++m_revision;
    emit revisionChanged();
}

QString Images::cached(const QString &file, const QString &url)
{
    if (QFile::exists(file))
        return QUrl::fromLocalFile(file).toString();
    if (m_running.contains(file) || m_failed.contains(file))
        return QString();

    const int tag = m_nextTag++;
    m_pending.insert(tag, file);
    m_running.insert(file);
    m_http->request(tag, "GET", url, QByteArray(), QStringList());
    return QString();
}

QString Images::photo(const QString &imageId, int width, int revision)
{
    Q_UNUSED(revision)
    if (imageId.isEmpty() || imageId.startsWith("00000000-0000"))
        return QString();

    // Die Breite haengt hinten an der Adresse; ohne sie kommt das volle
    // Bild.
    QString url = QString::fromLatin1(BaseUrl) + "images/BySize/" + imageId + "/";
    if (width > 0)
        url += QString::number(width);

    return cached(m_directory + "/" + imageId + "-" + QString::number(width) + ".jpg",
                  url);
}

QString Images::tile(int z, int x, int y, int revision)
{
    Q_UNUSED(revision)
    if (z < 0 || x < 0 || y < 0)
        return QString();
    const int span = 1 << z;
    if (x >= span || y >= span)
        return QString();

    // google3857 zaehlt /{z}/{y}/{x} -- Zeile vor Spalte, nicht wie bei
    // OSM. Wer das vertauscht, bekommt eine Karte, die stimmt, solange man
    // auf der Diagonale bleibt.
    const QString url = QString::fromLatin1(satellite() ? TileAerial : TileMap)
            .arg(z).arg(y).arg(x);
    const QString art = satellite() ? "luft" : "plan";
    const QString file = QString("%1/kacheln/%2-%3-%4-%5.img")
            .arg(m_directory).arg(art).arg(z).arg(x).arg(y);
    return cached(file, url);
}

void Images::clearCache()
{
    QDir directory(m_directory);
    QStringList files = directory.entryList(QStringList() << "*.jpg", QDir::Files);
    for (int i = 0; i < files.size(); ++i)
        QFile::remove(m_directory + "/" + files.at(i));
    QDir tiles(m_directory + "/kacheln");
    files = tiles.entryList(QStringList() << "*.img", QDir::Files);
    for (int i = 0; i < files.size(); ++i)
        QFile::remove(m_directory + "/kacheln/" + files.at(i));
    m_failed.clear();
    ++m_revision;
    emit revisionChanged();
}

void Images::replyFinished(int tag, int status, const QByteArray &body,
                           const QString &error)
{
    Q_UNUSED(error)
    const QString file = m_pending.take(tag);
    if (file.isEmpty())
        return;
    m_running.remove(file);

    if (status < 200 || status >= 300 || body.isEmpty()) {
        // Nicht endlos erneut versuchen -- sonst laeuft die Liste beim
        // Blaettern in eine Schleife aus Fehlversuchen.
        m_failed.insert(file);
        return;
    }

    QFile out(file);
    if (!out.open(QIODevice::WriteOnly)) {
        m_failed.insert(file);
        return;
    }
    out.write(body);
    out.close();

    ++m_revision;
    emit revisionChanged();
}
