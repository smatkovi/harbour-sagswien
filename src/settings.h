#ifndef SETTINGS_H
#define SETTINGS_H

#include <QObject>
#include <QSettings>
#include <QString>

// Was die App zwischen zwei Starts behaelt.
//
// Organisations- und Anwendungsname muessen zur Kennung in der
// Startdatei passen; auf Sailfish gibt der Sandkasten der App sonst bei
// jedem Start aus dem Symbol einen anderen, leeren Speicher -- und sie
// vergisst, was man ihr gesagt hat.
//
// Das Wichtigste hier ist die Geraetekennung: der Dienst der Stadt Wien
// kennt keine Anmeldung, die geraetInfoId **ist** die Sitzung. Wird sie
// verloren, ist man ein neuer Gast und sieht die eigenen Meldungen nicht
// mehr als eigene.
class Settings : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString nickname READ nickname NOTIFY profileChanged)
    Q_PROPERTY(bool satelliteMap READ satelliteMap WRITE setSatelliteMap
               NOTIFY satelliteMapChanged)
    // 0 = alle Meldungen, 1 = in der Naehe, 2 = eigene
    Q_PROPERTY(int startList READ startList WRITE setStartList NOTIFY startListChanged)
    Q_PROPERTY(int searchRadius READ searchRadius WRITE setSearchRadius
               NOTIFY searchRadiusChanged)

public:
    explicit Settings(QObject *parent = 0);

    // Keine Eigenschaft: die Kennung hat in QML nichts zu suchen.
    QString deviceId() const;
    void setDeviceId(const QString &id);

    QString profileId() const;
    void setProfileId(const QString &id);

    QString nickname() const;
    void setNickname(const QString &name);

    bool satelliteMap() const;
    void setSatelliteMap(bool satellite);

    int startList() const;
    void setStartList(int list);

    // Umkreis der Naheliste in Metern.
    int searchRadius() const;
    void setSearchRadius(int metres);

signals:
    void profileChanged();
    void satelliteMapChanged();
    void startListChanged();
    void searchRadiusChanged();

private:
    QSettings m_store;
};

#endif
