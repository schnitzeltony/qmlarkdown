#include "cmarkwrapper.h"
#include <cmark.h>
#include <QQmlEngine>
#include <QFile>

CMarkWrapper::CMarkWrapper(QObject *parent) : QObject(parent)
{

}

int CMarkWrapper::registerQML()
{
  return qmlRegisterSingletonType<CMarkWrapper>("CMark", 1, 0, "CMark", CMarkWrapper::getQMLInstance);
}

QObject *CMarkWrapper::getQMLInstance(QQmlEngine *t_engine, QJSEngine *t_scriptEngine)
{
  Q_UNUSED(t_engine)
  Q_UNUSED(t_scriptEngine)

  return new CMarkWrapper();
}

QString CMarkWrapper::stringToHtml(TreatParam paramAs, const QString &strIn)
{
  QByteArray tmpData;
  switch(paramAs) {
    case AsString:
      tmpData = strIn.toUtf8();
      break;
    case AsFilename: {
      QFile cmFile(strIn);
      if(cmFile.exists() && cmFile.open(QFile::ReadOnly | QFile::Unbuffered)) {
        tmpData = cmFile.readAll();
        cmFile.close();
      }
      break;
    }
  }
  return QString::fromUtf8(cmark_markdown_to_html(tmpData.constData(), size_t(tmpData.size()), CMARK_OPT_DEFAULT));
}

