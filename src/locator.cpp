#include "locator.h"

namespace
{
// So lange wird auf einen Fix gewartet, bevor die Seite die Adresssuche
// anbietet. Das N9 braucht kalt gern eine Minute; laenger warten zu lassen
// heisst, dem Nutzer nicht zu sagen, dass er tippen kann.
const int TimeoutMs = 90 * 1000;
}

Locator::Locator(QObject *parent) :
    QObject(parent),
    m_source(QGeoPositionInfoSource::createDefaultSource(this)),
    m_valid(false),
    m_searching(false),
    m_announced(false),
    m_latitude(0),
    m_longitude(0),
    m_accuracy(0)
{
    m_timeout.setSingleShot(true);
    m_timeout.setInterval(TimeoutMs);
    connect(&m_timeout, SIGNAL(timeout()), this, SLOT(giveUp()));

    if (m_source) {
        m_source->setUpdateInterval(2000);
        connect(m_source, SIGNAL(positionUpdated(QGeoPositionInfo)),
                this, SLOT(positionUpdated(QGeoPositionInfo)));
    }
}

void Locator::setSearching(bool searching)
{
    if (m_searching == searching)
        return;
    m_searching = searching;
    emit searchingChanged();
}

void Locator::start()
{
    if (!m_source)
        return;
    setSearching(true);
    m_timeout.start();
    m_source->startUpdates();
}

void Locator::stop()
{
    m_timeout.stop();
    setSearching(false);
    if (m_source)
        m_source->stopUpdates();
}

void Locator::giveUp()
{
    setSearching(false);
}

void Locator::setManual(double latitude, double longitude)
{
    stop();
    m_latitude = latitude;
    m_longitude = longitude;
    m_accuracy = 0;
    m_valid = true;
    emit positionChanged();
    emit fixed(latitude, longitude);
}

void Locator::positionUpdated(const QGeoPositionInfo &info)
{
    if (!info.isValid())
        return;
    const QGeoCoordinate where = info.coordinate();
    if (!where.isValid())
        return;

    m_latitude = where.latitude();
    m_longitude = where.longitude();
    if (info.hasAttribute(QGeoPositionInfo::HorizontalAccuracy))
        m_accuracy = info.attribute(QGeoPositionInfo::HorizontalAccuracy);
    m_valid = true;
    emit positionChanged();

    if (!m_announced) {
        m_announced = true;
        m_timeout.stop();
        setSearching(false);
        emit fixed(m_latitude, m_longitude);
    }
}
