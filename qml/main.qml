import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.VirtualKeyboard 2.4
import QtQuick.Window 2.12
import QtQuick.Controls.Material 2.12
import QtWebEngine 1.8
import QtQuick.Layouts 1.12
import Qt.labs.settings 1.0
import Qt.labs.platform 1.0
import QtQuick.Dialogs 1.3

import MarkDownQt 1.0
import QtHelper 1.0
import "qrc:/qml/controls" as CTRLS
import "qrc:/qml/functionals" as FUNCTIONALS
import "qrc:/fa-js-wrapper/fa-solid-900.js" as FA_SOLID


ApplicationWindow {
    id: window
    visible: true
    width: 800
    height: 600
    visibility: "Maximized"
    title: qsTr("Simple WYSIWYG MarkDown editor")

    Settings {
        id: settings
        // interactive
        property alias projectPath: projectPath.text
        property alias convertType: comboConvert.currentIndex
        property alias style: comboStyle.currentIndex
        // non-interactive
        property string helpUrl: "https://commonmark.org/help/"
    }

    FUNCTIONALS.MdHtmlConvMachine {
        id: htmlConverter
        onConversionDone: {
            tabsConverted.handleNewHtmlData(bHtmlBareChange, bHtmlPositionChange, bHtmlStyleChange)
        }
    }

    readonly property var styleStrings: [qsTr("Default Style"), qsTr("Github CSS")]
    function isGithubStyle() {
        return comboStyle.currentIndex === 1
    }
    function userMdActivity(backHome = false) {
        if(backHome) {
            tabsConverted.handleNewHtmlData(true, true, true)
        }
        else {
            htmlConverter.userMdActivity(textIn.text, comboConvert.model[comboConvert.currentIndex], isGithubStyle(), textIn.cursorPosition)
        }
    }

    property bool showOnlineHelp: false
    readonly property string helpUrl: settings.helpUrl

    FontLoader {
        source: "qrc:/Font-Awesome/webfonts/fa-solid-900.ttf"
    }

    FileDialog {
        id: pdfFileDialog
        selectExisting: false
        selectMultiple: false
        folder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        title: qsTr("PDF export")
        nameFilters: [ qsTr("PDF files (*.pdf)"), qsTr("All files (*)") ]
        //defaultSuffix: "pdf" // not declared??
        onAccepted: {
            var fileName = fileUrls[0];
            // defaultSuffix got lost somehow ??
            if(!fileName.endsWith(".pdf")) {
                fileName += ".pdf"
            }
            var dataHtml = htmlConverter.convertToHtml(textIn.text, comboConvert.model[comboConvert.currentIndex], isGithubStyle())
            if(MarkDownQt.convertToFile("qtwebenginepdf", MarkDownQt.FormatHtmlUtf8, MarkDownQt.FormatPdfBin, dataHtml, fileName)) {
                console.log("PDF " + fileName + " created")
            }
            else {
                console.error("PDF " + fileName + " not created!")
            }

        }
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
        // Source toolbar
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
                    onReleased: {
                        pdfFileDialog.open()
                        textIn.forceActiveFocus()
                    }
                }
                Item { // just margin
                    Layout.fillWidth: true
                }
                Label {
                    text: qsTr("Converter:")
                    color: "white"
                }
                ComboBox {
                    id: comboConvert
                    model: MarkDownQt.availableConverters(MarkDownQt.FormatMdUtf8, MarkDownQt.FormatHtmlUtf8)
                    onCurrentIndexChanged: {
                        userMdActivity()
                        textIn.forceActiveFocus()
                    }
                }
                Item { // just margin
                    width: 2
                }
            }
        }
        // Source input
        CTRLS.MdInput {
            id: textIn
            anchors.top: sourceToolBar.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: parent.width / 2
            onTextChanged: userMdActivity()
            onCursorPositionChanged: userMdActivity()
        }

        // Toolbar converted
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
                    onReleased: {
                        !showOnlineHelp ? userMdActivity(true) : helpViewLoader.item.url = helpUrl
                        textIn.forceActiveFocus()
                    }
                }
                Item { // just margin
                    width: 5
                }
                Label {
                    text: qsTr("Project Path:")
                    color: "white"
                }
                TextField {
                    id: projectPath
                    Layout.fillWidth: true
                    selectByMouse: true
                    onTextChanged: {
                        if(QtHelper.pathExists(text)) {
                            color = "black"
                            userMdActivity()
                        }
                        else {
                            color = "red"
                        }
                    }
                }
                ComboBox {
                    id: comboStyle
                    model: styleStrings
                    onCurrentIndexChanged: {
                        userMdActivity()
                        textIn.forceActiveFocus()
                    }
                }
                Button {
                    font.family: "Font Awesome 5 Free"
                    font.pointSize: 16
                    text: FA_SOLID.icon(!showOnlineHelp ? FA_SOLID.fa_solid_900_question : FA_SOLID.fa_solid_900_backward)
                    Layout.preferredWidth: height
                    onReleased: {
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

        // converted contents / online-help swipe
        SwipeView {
            anchors.top: htmlToolBar.bottom
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            width: parent.width / 2
            clip: true
            currentIndex: showOnlineHelp ? 1 : 0
            interactive: false

            CTRLS.TabsConverted {
                id: tabsConverted
                propertyHtmlConverter: htmlConverter
            }
            Loader {
                id: helpViewLoader
                active: false
                sourceComponent: WebEngineView {
                    id: webHelpView
                    url: helpUrl
                    onContextMenuRequested: function(request) {
                        request.accepted = true;
                    }
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
