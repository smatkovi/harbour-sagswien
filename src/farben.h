#ifndef FARBEN_H
#define FARBEN_H

#include <QColor>
#include <QObject>

// Die Hausfarben, an einer Stelle und fuer beide Ausgaben gleich.
//
// Rot ist das Feld des Original-Symbols, aus dem VectorDrawable der App
// abgelesen (#ff5963, nicht geschaetzt); dazu das Rot des Stadtwappens
// (#ff0000), Weiss und zwei Grautoene.
//
// Das liegt in C++ und nicht als QML-Singleton, weil Qt 4.7 auf Harmattan
// keine Singletons kennt und die Seiten beider Ausgaben dieselben Namen
// benutzen sollen.
//
// **Es heisst AppTheme, nicht Theme**: com.nokia.meego bringt selbst ein
// `theme` mit, und eine Kontext-Eigenschaft dieses Namens wird davon
// verdeckt -- die Seiten bekaemen dann stumm das falsche Objekt.
class Farben : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QColor rot READ rot CONSTANT)
    Q_PROPERTY(QColor rotDunkel READ rotDunkel CONSTANT)
    Q_PROPERTY(QColor wappenRot READ wappenRot CONSTANT)
    Q_PROPERTY(QColor weiss READ weiss CONSTANT)
    Q_PROPERTY(QColor schwarz READ schwarz CONSTANT)
    Q_PROPERTY(QColor grau READ grau CONSTANT)
    Q_PROPERTY(QColor grauHell READ grauHell CONSTANT)

public:
    explicit Farben(QObject *parent = 0) : QObject(parent) {}

    QColor rot() const { return QColor("#ff5963"); }
    QColor rotDunkel() const { return QColor("#c0323c"); }
    QColor wappenRot() const { return QColor("#ff0000"); }
    QColor weiss() const { return QColor("#ffffff"); }
    QColor schwarz() const { return QColor("#000000"); }
    QColor grau() const { return QColor("#8c8c8c"); }
    QColor grauHell() const { return QColor("#e6e6e6"); }
};

#endif
