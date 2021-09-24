#include <iostream>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QFile>
#include "utils/ImageTools.h"

int main(int argc, char* argv[]) {
    #if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
        QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    #endif

    QGuiApplication app(argc, argv);
    app.setOrganizationName("eramne");
    app.setOrganizationDomain("eramne.com");
    app.setApplicationName("umagos");

    QQmlApplicationEngine engine;
    const QUrl url(QStringLiteral("qrc:/app/qml/app.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject* obj, const QUrl& objUrl) {
        if (!obj && url == objUrl) {
            QCoreApplication::exit(-1);
        }
    }, Qt::QueuedConnection);
    engine.load(url);

    qInfo("Starting conversion.");
    ImageTools::convertImage("C:/Users/student/Desktop/image8.jpg", "C:/Users/student/Desktop/image8.png");

    return app.exec();
}
