#include "qthelper.h"
#include <QQmlEngine>
#include <QDir>

QtHelper::QtHelper(QObject *parent) : QObject(parent)
{
}

int QtHelper::registerQML()
{
    return qmlRegisterSingletonType<QtHelper>("QtHelper", 1, 0, "QtHelper", QtHelper::getQMLInstance);
}

QObject *QtHelper::getQMLInstance(QQmlEngine *t_engine, QJSEngine *t_scriptEngine)
{
    Q_UNUSED(t_engine)
    Q_UNUSED(t_scriptEngine)

    return new QtHelper();
}

QByteArray QtHelper::strToUtf8Data(QString strIn)
{
    return strIn.toUtf8();
}

QString QtHelper::utf8DataToStr(QByteArray dataIn)
{
    return QString::fromUtf8(dataIn);
}

bool QtHelper::pathExists(QString strPath)
{
    return QDir(strPath).exists();
}
