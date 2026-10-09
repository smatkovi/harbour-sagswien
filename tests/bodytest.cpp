// Prueft den Anlege-Weg, ohne ihn abzuschicken.
//
// Der Dienst der Stadt Wien hat **keinen Testserver** (gesucht und nicht
// gefunden, doc/BEFUND.md Abschnitt 11). Jede abgeschickte Meldung ist
// eine echte Beschwerde beim Magistrat. `PUT Meldung` wird beim
// Entwickeln also nie aufgerufen -- und damit ist dieser Test die einzige
// Stelle, an der sich der gebaute Koerper ueberhaupt kontrollieren laesst.
//
// Geprueft wird gegen das, was aus der Original-App ausgelesen wurde:
// die Feldnamen des MeldungDto und des AdressDTO, und vor allem die zwei
// Fallen, die den Dienst sonst mit HTTP 400 antworten lassen --
// Aufzaehlungen als Zahl und die Nullkennung fuer Neues.
//
//   g++ -I../src tests/bodytest.cpp src/api.cpp src/json.cpp ... -o bodytest
//
// Gebaut und gelaufen wird er von tests/run.sh.
#include "api.h"
#include "json.h"

#include <QDateTime>
#include <QStringList>
#include <QTextStream>
#include <QVariantMap>

static int fehler = 0;
static QTextStream aus(stdout);

static void pruefe(bool bedingung, const QString &was)
{
    if (!bedingung) {
        aus << "FEHLER: " << was << "\n";
        ++fehler;
    }
}

int main(int argc, char *argv[])
{
    Q_UNUSED(argc)
    Q_UNUSED(argv)

    // Die Adressfelder so, wie applyAddress() sie aus dem OGD-Dienst der
    // Stadt fuellt -- nachgemessen an der Sturzgasse 6A.
    QVariantMap adresse;
    adresse.insert("strasse", "Sturzgasse");
    adresse.insert("hausnummer", "6A");
    adresse.insert("plz", 1150);
    adresse.insert("ort", "Wien");
    adresse.insert("acd", "102956");
    adresse.insert("scd", "04798");
    adresse.insert("bezirk", "15");
    adresse.insert("adresse", "Sturzgasse 6A");

    QStringList kategorien;
    kategorien << "64fe802d-fffa-5ad8-5bd0-b2879a87fd6e";

    const QDateTime wann = QDateTime::fromString("2026-10-09T13:35:41",
                                                 "yyyy-MM-ddTHH:mm:ss");

    const QByteArray roh = Api::buildReport(
                "334d5f59-a196-4804-966a-37b727cef7d9", "0.1.0",
                "Das Schlagloch vor dem Haus wird groesser.",
                kategorien, QStringList(),
                48.19411164524335, 16.316122532306906, adresse, wann);

    QString klage;
    const QVariant gelesen = Json::parse(roh, &klage);
    pruefe(gelesen.isValid(), "Der Koerper ist kein gueltiges JSON: " + klage);
    const QVariantMap body = gelesen.toMap();

    // --- Die Pflichtfelder des MeldungDto (Maske 15 im Modell der App) ---
    pruefe(body.contains("meldungId"), "meldungId fehlt");
    pruefe(body.contains("status"), "status fehlt");
    pruefe(body.contains("adresse"), "adresse fehlt");
    pruefe(body.contains("tsMeldung"), "tsMeldung fehlt");
    pruefe(body.contains("geraetInfoId"), "geraetInfoId fehlt");

    // --- Falle 1: Aufzaehlungen sind Zahlen, keine Zeichenketten ---
    // "status":"0" beantwortet der Dienst mit HTTP 400
    // ("The JSON value could not be converted to ...StatusTypen").
    pruefe(!roh.contains("\"status\":\"") , "status steht als Zeichenkette im JSON");
    pruefe(body.value("status").toInt() == 0, "status ist nicht 0");
    pruefe(roh.contains("\"status\":0"), "status steht nicht als nackte Zahl");

    // --- Falle 2: Neues traegt die Nullkennung ---
    pruefe(body.value("meldungId").toString()
           == "00000000-0000-0000-0000-000000000000",
           "eine neue Meldung traegt nicht die Nullkennung");

    // --- Die Sitzung steht im Koerper, nicht in einem Kopf ---
    pruefe(body.value("geraetInfoId").toString()
           == "334d5f59-a196-4804-966a-37b727cef7d9",
           "die Geraetekennung steht nicht im Koerper");

    // --- Die Adresse: Zahlen bleiben Zahlen ---
    const QVariantMap wo = body.value("adresse").toMap();
    pruefe(wo.value("latitude").toDouble() > 48.19 && wo.value("latitude").toDouble() < 48.20,
           "latitude falsch");
    pruefe(wo.value("longitude").toDouble() > 16.31 && wo.value("longitude").toDouble() < 16.32,
           "longitude falsch");
    // plz ist im Meldungsmodell eine Zahl (nachgemessen: "plz": 1150),
    // im Adressdienst dagegen eine Zeichenkette -- hier muss sie Zahl sein.
    pruefe(!roh.contains("\"plz\":\""), "plz steht als Zeichenkette im JSON");
    pruefe(wo.value("plz").toInt() == 1150, "plz falsch");
    pruefe(wo.value("scd").toString() == "04798", "scd fehlt oder falsch");
    pruefe(wo.value("adresse").toString() == "Sturzgasse 6A", "adresse falsch");
    // Auch die Adresse traegt die Geraetekennung -- so macht es die App.
    pruefe(wo.contains("geraetInfoId"), "die Adresse traegt keine Geraetekennung");

    // --- Kategorien als Liste von Kennungen ---
    const QVariantList ids = body.value("kategorieIds").toList();
    pruefe(ids.size() == 1, "kategorieIds hat nicht genau einen Eintrag");
    pruefe(ids.value(0).toString() == "64fe802d-fffa-5ad8-5bd0-b2879a87fd6e",
           "kategorieId falsch");

    // --- Zeitstempel mit Zonenversatz, so wie der Dienst ihn schreibt ---
    const QString ts = body.value("tsMeldung").toString();
    pruefe(ts.startsWith("2026-10-09T13:35:41"),
           "tsMeldung hat nicht die Form des Dienstes: " + ts);
    pruefe(ts.length() == 25 && (ts.at(19) == '+' || ts.at(19) == '-'),
           "tsMeldung traegt keinen Zonenversatz: " + ts);

    // --- Ohne Fotos bleibt images eine leere Liste, nicht null ---
    pruefe(body.contains("images"), "images fehlt");
    pruefe(body.value("images").toList().isEmpty(), "images ist nicht leer");

    // --- Und nichts davon darf den Dienst anfassen ---
    aus << (fehler ? QString("%1 Fehler\n").arg(fehler)
                   : QString("Meldungskoerper in Ordnung (nichts abgeschickt)\n"));
    return fehler ? 1 : 0;
}
