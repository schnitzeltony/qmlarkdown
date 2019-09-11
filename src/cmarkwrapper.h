#ifndef CMARKWRAPPER_H
#define CMARKWRAPPER_H

#include <QObject>
QT_BEGIN_NAMESPACE
class QQmlEngine;
class QJSEngine;
QT_END_NAMESPACE

class CMarkWrapper : public QObject
{
  Q_OBJECT
public:
  enum TreatParam {
      AsString = 0,
      AsFilename = 1,
  };
  Q_ENUM(TreatParam)

  /**
   * @brief Register CMark 1.0 to Qml
   * @return return value of qmlRegisterSingletonType
   */
  static int registerQML();

  /**
   * @brief Transforms Commonmark to HTML
   * @param paramAs How to treat str parameter see TreatParam
   * @param strIn Either Commonmark formatted text or filename or..
   * @return Text in HTML format
   */
  Q_INVOKABLE static QString stringToHtml(TreatParam paramAs, const QString &strIn);

signals:

public slots:

private:
  explicit CMarkWrapper(QObject *parent = nullptr);
  static QObject *getQMLInstance(QQmlEngine *t_engine, QJSEngine *t_scriptEngine);
};

#endif // CMARKWRAPPER_H
