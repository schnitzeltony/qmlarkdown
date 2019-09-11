#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QtWebEngine>
#include "cmarkwrapper.h"

int main(int argc, char *argv[])
{
  //qputenv("QT_IM_MODULE", QByteArray("qtvirtualkeyboard"));
  qunsetenv("QT_IM_MODULE");

  // register CMarkWrapper as singleton
  CMarkWrapper::registerQML();

  QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

  QGuiApplication app(argc, argv);

  QtWebEngine::initialize();

  QQmlApplicationEngine engine;
  const QUrl url(QStringLiteral("qrc:/main.qml"));
  QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                   &app, [url](QObject *obj, const QUrl &objUrl) {
    if (!obj && url == objUrl)
      QCoreApplication::exit(-1);
  }, Qt::QueuedConnection);
  engine.load(url);

  return app.exec();
}
