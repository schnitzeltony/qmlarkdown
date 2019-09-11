import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.VirtualKeyboard 2.4
import QtQuick.Window 2.12
import QtQuick.Controls.Material 2.12
import QtWebEngine 1.8
import CMark 1.0

ApplicationWindow {
  id: window
  visible: true
  width: 640
  height: 480
  visibility: "Maximized"
  title: qsTr("Simple WYSIWYG CommonMark editor")

  Flickable {
      Material.theme: Material.Dark
      id: mainFlickable
      anchors.fill: parent
      contentWidth: parent.width;
      contentHeight: parent.height//+inputPanel.realHeight
      boundsBehavior: Flickable.StopAtBounds
      interactive: false
      NumberAnimation on contentY
      {
          duration: 300
          id: flickableAnimation
      }
      ScrollView {
        anchors.top: parent.top
        anchors.left: parent.left
        height: parent.height
        width: parent.width / 2
        padding: 8
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOn //AsNeeded
        ScrollBar.vertical.policy: ScrollBar.AlwaysOn
        TextArea {
          id: textIn
          wrapMode: TextEdit.NoWrap
          onTextChanged: {
            webView.loadHtml(CMark.stringToHtml(0, text), "")
          }
        }
      }
      Rectangle {
        id: htmlTools
        anchors.top: parent.top
        anchors.right: parent.right
        height: 50
        width: parent.width / 2
        color: Material.background
      }

      WebEngineView {
        id: webView
        anchors.top: htmlTools.bottom
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        //height: parent.height
        width: parent.width / 2
      }
  }

  /*InputPanel {
       id: inputPanel
       anchors.left: parent.left
       anchors.right: parent.right
       anchors.bottom: parent.bottom
       property bool textEntered: Qt.inputMethod.visible
       // Hmm - why is this necessary?
       property real realHeight: height/1.65
       opacity: 0
       NumberAnimation on opacity
       {
           id: keyboardAnimation
           onStarted: {
               if(to === 1) {
                   inputPanel.visible = true
               }
           }
           onFinished: {
               if(to === 0) {
                   inputPanel.visible = false
               }
           }
       }
       onTextEnteredChanged: {
           var rectInput = Qt.inputMethod.anchorRectangle
           if (inputPanel.textEntered)
           {
              if(rectInput.bottom > inputPanel.y)
              {
                  flickableAnimation.to = rectInput.bottom - inputPanel.y + 10
                  flickableAnimation.start()
              }
              keyboardAnimation.to = 1
              keyboardAnimation.duration = 500
              keyboardAnimation.start()
           }
           else
           {
               if(mainFlickable.contentY !== 0)
               {
                   flickableAnimation.to = 0
                   flickableAnimation.start()
               }
               keyboardAnimation.to = 0
               keyboardAnimation.duration = 0
               keyboardAnimation.start()
           }
       }
  }*/
}
