#ifndef STUBS_H
#define STUBS_H

#include <QColor>
#include <QObject>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

// Attrappen fuer die fuenf Objekte, mit denen die Seiten reden.
//
// Der Pruefer liest die QML nur ein und loest ihre Bindungen auf; die
// Attrappen brauchen also die richtigen Namen und Signaturen und sonst
// nichts. Sie stehen hier ausgeschrieben und werden nicht aus den echten
// Headern erzeugt, weil die QtMobility hereinziehen -- und das hat das
// Desktop-Qt des Baurechners nicht. Driftet eine Attrappe von der echten
// Klasse weg, faengt das der ARM-Bau ab, der die echten nimmt.
class StubFormat : public QObject
{
    Q_OBJECT
public:
    Q_INVOKABLE QString statusName(int) const { return "Neu"; }
    Q_INVOKABLE QString statusColor(int) const { return "#e8453c"; }
    Q_INVOKABLE QString when(const QString &) const { return "1.1.2026, 00:00"; }
    Q_INVOKABLE QString categories(const QVariantMap &) const { return "Strassen"; }
    Q_INVOKABLE QString address(const QVariantMap &) const { return "1150 Sturzgasse 6A"; }
    Q_INVOKABLE QString distance(const QVariant &) const { return "120 m"; }
    Q_INVOKABLE QStringList imageIds(const QVariantMap &) const { return QStringList(); }
};

class StubApi : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool ready READ flag NOTIFY changed)
    Q_PROPERTY(bool busy READ flag NOTIFY changed)
    Q_PROPERTY(QString lastError READ text NOTIFY changed)
    Q_PROPERTY(QVariantList categories READ list NOTIFY changed)
    Q_PROPERTY(QVariantList reports READ list NOTIFY changed)
    Q_PROPERTY(QVariantMap report READ map NOTIFY changed)
    Q_PROPERTY(QString nickname READ text NOTIFY changed)
    Q_PROPERTY(int listType READ number NOTIFY changed)
    Q_PROPERTY(bool hasPosition READ flag NOTIFY changed)
    Q_PROPERTY(double latitude READ real NOTIFY changed)
    Q_PROPERTY(double longitude READ real NOTIFY changed)
    Q_PROPERTY(QString address READ text NOTIFY changed)

public:
    bool flag() const { return false; }
    QString text() const { return QString(); }
    QVariantList list() const { return QVariantList(); }
    QVariantMap map() const { return QVariantMap(); }
    int number() const { return 0; }
    double real() const { return 0; }

public slots:
    void start() {}
    void fetchCategories() {}
    void fetchReports(int) {}
    void refresh() {}
    void fetchReport(const QString &) {}
    void setPosition(double, double) {}
    void lookupAddress(const QString &) {}
    QString imageUrl(const QString &, int) const { return QString(); }
    void submitReport(const QString &, const QStringList &, const QStringList &) {}

signals:
    void changed();
    void reportSubmitted(const QString &meldungId);
    void lastErrorChanged();
};

class StubImages : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int revision READ number NOTIFY changed)
    Q_PROPERTY(bool satellite READ flag WRITE setFlag NOTIFY changed)

public:
    int number() const { return 0; }
    bool flag() const { return false; }
    void setFlag(bool) {}

    Q_INVOKABLE QString photo(const QString &, int, int = 0) { return QString(); }
    Q_INVOKABLE QString tile(int, int, int, int = 0) { return QString(); }
    Q_INVOKABLE void clearCache() {}

signals:
    void changed();
};

class StubLocator : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool valid READ flag NOTIFY changed)
    Q_PROPERTY(bool searching READ flag NOTIFY changed)
    Q_PROPERTY(double latitude READ real NOTIFY changed)
    Q_PROPERTY(double longitude READ real NOTIFY changed)
    Q_PROPERTY(double accuracy READ real NOTIFY changed)
    Q_PROPERTY(bool available READ flag CONSTANT)

public:
    bool flag() const { return false; }
    double real() const { return 0; }

public slots:
    void start() {}
    void stop() {}
    void setManual(double, double) {}

signals:
    void changed();
};

class StubSettings : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString nickname READ text NOTIFY changed)
    Q_PROPERTY(bool satelliteMap READ flag WRITE setFlag NOTIFY changed)
    Q_PROPERTY(int startList READ number WRITE setNumber NOTIFY changed)
    Q_PROPERTY(int searchRadius READ number WRITE setNumber NOTIFY changed)

public:
    QString text() const { return QString(); }
    bool flag() const { return false; }
    void setFlag(bool) {}
    int number() const { return 0; }
    void setNumber(int) {}

signals:
    void changed();
};

// Die Farbtafel. Sie heisst in der QML **AppTheme**, nicht Theme --
// com.nokia.meego bringt ein eigenes `theme` mit und verdeckt den Namen.
class StubFarben : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QColor rot READ farbe CONSTANT)
    Q_PROPERTY(QColor rotDunkel READ farbe CONSTANT)
    Q_PROPERTY(QColor wappenRot READ farbe CONSTANT)
    Q_PROPERTY(QColor weiss READ farbe CONSTANT)
    Q_PROPERTY(QColor schwarz READ farbe CONSTANT)
    Q_PROPERTY(QColor grau READ farbe CONSTANT)
    Q_PROPERTY(QColor grauHell READ farbe CONSTANT)

public:
    QColor farbe() const { return QColor("#ff5963"); }
};

#endif
