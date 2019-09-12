import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.VirtualKeyboard 2.4
import QtQuick.Window 2.12
import QtQuick.Controls.Material 2.12
import QtWebEngine 1.8
import QtQuick.Layouts 1.12

import CMark 1.0
import "qrc:/fa-js-wrapper/fa-solid-900.js" as FA_SOLID


ApplicationWindow {
    id: window
    visible: true
    width: 800
    height: 600
    visibility: "Maximized"
    title: qsTr("Simple WYSIWYG MarkDown editor")

    // TODO: enum use here and for CMark
    property bool showQtLabelBox: comboStyle.currentIndex === 1
    property var styleStrings: [qsTr("Default Style"), qsTr("QT/QML Label Style"), qsTr("Github Style")]
    property var convertStrings: ["Cmark", "Sundown"]

    property bool showOnlineHelp: false
    readonly property string helpUrl: "https://commonmark.org/help/"

    function updateHtml() {
        var styleHtml = 0
        switch(comboStyle.currentIndex) {
        case 0: // default
            break;
        case 1: // QLabel
            break;
        case 2: // github
            styleHtml = 1
            break;
        }

        webView.loadHtml(CMark.stringToHtml(0, textIn.text, styleHtml), baseUri.text)
        qtLabelView.text = CMark.stringToHtml(0, textIn.text, styleHtml)
    }

    FontLoader {
        source: "qrc:/Font-Awesome/webfonts/fa-solid-900.ttf"
    }

    Timer {
        id: userInputTimer
        interval: 500;
        onTriggered: updateHtml()
    }

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
        Rectangle {
            id: sourceToolBar
            anchors.top: parent.top
            anchors.left: parent.left
            height: 50
            width: parent.width / 2
            color: Material.background
            RowLayout {
                anchors.fill: parent
                Item { // just margin
                    width: 2
                }
                Button {
                    font.family: "Font Awesome 5 Free"
                    font.pointSize: 16
                    text: FA_SOLID.icon(FA_SOLID.fa_solid_900_file)
                    Layout.preferredWidth: height
                }
                Button {
                    font.family: "Font Awesome 5 Free"
                    font.pointSize: 16
                    text: FA_SOLID.icon(FA_SOLID.fa_solid_900_folder_open)
                    Layout.preferredWidth: height
                }
                Button {
                    font.family: "Font Awesome 5 Free"
                    font.pointSize: 16
                    text: FA_SOLID.icon(FA_SOLID.fa_solid_900_save)
                    Layout.preferredWidth: height
                }
                Button {
                    font.family: "Font Awesome 5 Free"
                    font.pointSize: 16
                    text: FA_SOLID.icon(FA_SOLID.fa_solid_900_file_pdf)
                    Layout.preferredWidth: height
                }
                Item { // just margin
                    Layout.fillWidth: true
                }
                Label {
                    text: qsTr("Converter:")
                    color: "white"
                }
                ComboBox {
                    id: comboConver
                    model: convertStrings
                }
                Item { // just margin
                    width: 2
                }
            }
        }
        ScrollView {
            anchors.top: sourceToolBar.bottom
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
                    userInputTimer.restart()
                }
            }
        }
        Rectangle {
            id: htmlToolBar
            anchors.top: parent.top
            anchors.right: parent.right
            height: 50
            width: parent.width / 2
            color: Material.background
            RowLayout {
                anchors.fill: parent
                Item { // just margin
                    width: 2
                }
                Button {
                    font.family: "Font Awesome 5 Free"
                    font.pointSize: 16
                    text: FA_SOLID.icon(FA_SOLID.fa_solid_900_home)
                    Layout.preferredWidth: height
                    onPressed: !showOnlineHelp ? updateHtml() : helpViewLoader.item.url = helpUrl
                }
                Item { // just margin
                    width: 5
                }
                Label {
                    text: qsTr("Base URL:")
                    color: "white"
                }
                TextField {
                    id: baseUri
                    Layout.fillWidth: true
                    onTextChanged: updateHtml()
                }
                ComboBox {
                    id: comboStyle
                    model: styleStrings
                    onCurrentIndexChanged: updateHtml()
                }
                Button {
                    font.family: "Font Awesome 5 Free"
                    font.pointSize: 16
                    text: FA_SOLID.icon(!showOnlineHelp ? FA_SOLID.fa_solid_900_question : FA_SOLID.fa_solid_900_backward)
                    Layout.preferredWidth: height
                    onPressed: {
                        // Keep help view once loaded
                        helpViewLoader.active = true
                        showOnlineHelp = !showOnlineHelp
                    }
                }
                Item { // just margin
                    width: 2
                }
            }
        }

        Label {
            id: qtLabelView
            anchors.top: htmlToolBar.bottom
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            width: parent.width / 2
            visible: showQtLabelBox && !showOnlineHelp
        }
        SwipeView {
            id: swipeHtml
            anchors.top: htmlToolBar.bottom
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            width: parent.width / 2
            clip: true
            currentIndex: showOnlineHelp ? 1 : 0
            visible: !showQtLabelBox || showOnlineHelp
            interactive: false
            WebEngineView {
                id: webView
            }
            Loader {
                id: helpViewLoader
                active: false
                sourceComponent: WebEngineView {
                    id: webHelpView
                    url: helpUrl
                }
            }
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
