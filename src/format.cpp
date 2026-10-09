#include "format.h"

#include <QDateTime>
#include <QLocale>
#include <QStringList>
#include <QVariantList>

QString Format::statusName(int status) const
{
    switch (status) {
    case 0: return tr("Neu");
    case 2: return tr("In Bearbeitung");
    case 4: return tr("Erledigt");
    case 8: return tr("Gelöscht");
    }
    return tr("Unbekannt");
}

QString Format::statusColor(int status) const
{
    switch (status) {
    case 0: return QLatin1String("#e8453c");
    case 2: return QLatin1String("#f2a02d");
    case 4: return QLatin1String("#3f9c45");
    case 8: return QLatin1String("#9e9e9e");
    }
    return QLatin1String("#9e9e9e");
}

QString Format::when(const QString &isoStamp) const
{
    if (isoStamp.isEmpty())
        return QString();
    // Der Dienst haengt den Zonenversatz an ("...+02:00"). Qt 4.7s
    // Qt::ISODate kann ihn nicht lesen und gibt ein ungueltiges Datum
    // zurueck -- deshalb erst die ersten 19 Zeichen nehmen, das ist die
    // Ortszeit des Servers und genau die, die angezeigt werden soll.
    const QDateTime stamp =
            QDateTime::fromString(isoStamp.left(19), QLatin1String("yyyy-MM-ddTHH:mm:ss"));
    if (!stamp.isValid())
        return isoStamp;
    return QLocale().toString(stamp.date(), QLocale::ShortFormat)
            + QLatin1String(", ") + stamp.time().toString(QLatin1String("HH:mm"));
}

QString Format::categories(const QVariantMap &report) const
{
    QVariant list = report.value(QLatin1String("Kategorien"));
    if (!list.isValid())
        list = report.value(QLatin1String("kategorien"));
    const QVariantList entries = list.toList();
    QStringList names;
    for (int i = 0; i < entries.size(); ++i) {
        const QString name =
                entries.at(i).toMap().value(QLatin1String("bezeichnung")).toString();
        if (!name.isEmpty())
            names << name;
    }
    return names.join(QLatin1String(", "));
}

QString Format::address(const QVariantMap &report) const
{
    const QVariantMap where = report.value(QLatin1String("adresse")).toMap();
    if (where.isEmpty())
        return QString();
    const QString street = where.value(QLatin1String("adresse")).toString();
    const QString town = where.value(QLatin1String("ort")).toString();
    if (street.isEmpty())
        return town;
    const int plz = where.value(QLatin1String("plz")).toInt();
    if (plz > 0)
        return QString::number(plz) + QLatin1Char(' ') + street;
    return street;
}

QString Format::distance(const QVariant &metres) const
{
    if (!metres.isValid() || metres.isNull())
        return QString();
    const int m = metres.toInt();
    if (m < 0)
        return QString();
    if (m < 1000)
        return QString::number(m) + QLatin1String(" m");
    return QLocale().toString(m / 1000.0, 'f', 1) + QLatin1String(" km");
}

QStringList Format::imageIds(const QVariantMap &report) const
{
    const QVariantList images = report.value(QLatin1String("images")).toList();
    QStringList ids;
    for (int i = 0; i < images.size(); ++i) {
        const QString id =
                images.at(i).toMap().value(QLatin1String("imageId")).toString();
        if (!id.isEmpty() && !id.startsWith(QLatin1String("00000000-0000")))
            ids << id;
    }
    return ids;
}
