#include "qthelper.h"
#include <markdown-qt.h>
#include <textarea_enhanced.h>
#include <fontawesome-qml.h>
#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QtWebEngine>

int main(int argc, char *argv[])
{
    //qputenv("QT_IM_MODULE", QByteArray("qtvirtualkeyboard"));
    qunsetenv("QT_IM_MODULE");

    QtWebEngine::initialize();

    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QApplication app(argc, argv);
    app.setOrganizationName("schnitzeltony");

    QQmlApplicationEngine engine;

    CMarkDownQt::setSettingsParameters(app.organizationName(), app.applicationName());
    CMarkDownQt::registerQML();
    QtHelper::registerQML();
    TextAreaEnhanced::registerQml(&engine);
    // Just registering solid-variant saves us from setting font.styleName all over the placed
    // code is still there in QML...
    FontAwesomeQml::registerFonts(false, true, false);
    FontAwesomeQml::registerFAQml(&engine);

    const QUrl url(QStringLiteral("qrc:/qml/Main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
