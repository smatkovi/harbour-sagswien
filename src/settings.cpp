#include "settings.h"

Settings::Settings(QObject *parent) :
    QObject(parent),
    m_store()
{
}

QString Settings::deviceId() const
{
    return m_store.value("geraetInfoId").toString();
}

void Settings::setDeviceId(const QString &id)
{
    if (deviceId() == id)
        return;
    m_store.setValue("geraetInfoId", id);
    m_store.sync();
}

QString Settings::profileId() const
{
    return m_store.value("profileId").toString();
}

void Settings::setProfileId(const QString &id)
{
    if (profileId() == id)
        return;
    m_store.setValue("profileId", id);
    m_store.sync();
}

QString Settings::nickname() const
{
    return m_store.value("nickname").toString();
}

void Settings::setNickname(const QString &name)
{
    if (nickname() == name)
        return;
    m_store.setValue("nickname", name);
    m_store.sync();
    emit profileChanged();
}

bool Settings::satelliteMap() const
{
    return m_store.value("satelliteMap", false).toBool();
}

void Settings::setSatelliteMap(bool satellite)
{
    if (satelliteMap() == satellite)
        return;
    m_store.setValue("satelliteMap", satellite);
    emit satelliteMapChanged();
}

int Settings::startList() const
{
    return m_store.value("startList", 1).toInt();
}

void Settings::setStartList(int list)
{
    if (startList() == list)
        return;
    m_store.setValue("startList", list);
    emit startListChanged();
}

int Settings::searchRadius() const
{
    return m_store.value("searchRadius", 1000).toInt();
}

void Settings::setSearchRadius(int metres)
{
    if (searchRadius() == metres)
        return;
    m_store.setValue("searchRadius", metres);
    emit searchRadiusChanged();
}
