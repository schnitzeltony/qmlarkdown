#include "qthelper.h"
#include <markdown-qt.h>
#include <ksyntaxhighlightingwrapper.h>
#include <fontawesome-qml.h>
#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QtWebEngine>

int main(int argc, char *argv[])
{
    //qputenv("QT_IM_MODULE", QByteArray("qtvirtualkeyboard"));
    qunsetenv("QT_IM_MODULE");


    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QApplication app(argc, argv);
    app.setOrganizationName("schnitzeltony");

    QtWebEngine::initialize();
    QQmlApplicationEngine engine;

    CMarkDownQt::setSettingsParameters(app.organizationName(), app.applicationName());
    CMarkDownQt::registerQML();
    QtHelper::registerQML();
    qmlRegisterType<KSyntaxHighlightingWrapper>("KSyntaxHighlighting", 1, 0, "KSyntaxHighlighting");
    FontAwesomeQml::registerFAQml();

    const QUrl url(QStringLiteral("qrc:/qml/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
