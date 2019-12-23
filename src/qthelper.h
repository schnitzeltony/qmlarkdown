#ifndef QTHELPER_H
#define QTHELPER_H

#include <QObject>

QT_BEGIN_NAMESPACE
class QQmlEngine;
class QJSEngine;
QT_END_NAMESPACE

class QtHelper : public QObject
{
    Q_OBJECT
public:
    static int registerQML();
    // Helpers (js TextEncoder/TextDecoder are not supported)
    Q_INVOKABLE static QByteArray strToUtf8Data(QString strIn);
    Q_INVOKABLE static QString utf8DataToStr(QByteArray dataIn);
    // The following are at least easier in Qt
    Q_INVOKABLE static bool pathExists(QString strPath);

signals:

public slots:

private:
    explicit QtHelper(QObject *parent = nullptr);
    static QObject *getQMLInstance(QQmlEngine *t_engine, QJSEngine *t_scriptEngine);
};

#endif // QTHELPER_H
