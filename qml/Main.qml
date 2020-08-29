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
import FontAwesomeQml 1.0
import KSyntaxHighlighting 1.0
import TextAreaEnhanced 1.0

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

    MdHtmlConvMachine {
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
            htmlConverter.userMdActivity(
                        textIn.textArea.text,
                        comboConvert.model[comboConvert.currentIndex],
                        isGithubStyle(),
                        textIn.textArea.cursorPosition)
        }
    }

    property bool showOnlineHelp: false
    readonly property string helpUrl: settings.helpUrl

    readonly property string faFontFamily: FAQ.fontFamily
    readonly property string faFontStyle: "" // if more than fa_solid is registered this has to be set to "Solid"
    readonly property real faPointSize: 16

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
            var dataHtml = htmlConverter.convertToHtml(
                        textIn.textArea.text,
                        comboConvert.model[comboConvert.currentIndex],
                        isGithubStyle())
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
                    font.family: faFontFamily
                    font.styleName: faFontStyle
                    font.pointSize: faPointSize
                    focusPolicy: Qt.NoFocus
                    text: FAQ.fa_file
                    Layout.preferredWidth: height
                }
                Button {
                    font.family: faFontFamily
                    font.styleName: faFontStyle
                    font.pointSize: faPointSize
                    focusPolicy: Qt.NoFocus
                    text: FAQ.fa_folder_open
                    Layout.preferredWidth: height
                }
                Button {
                    font.family: faFontFamily
                    font.styleName: faFontStyle
                    font.pointSize: faPointSize
                    focusPolicy: Qt.NoFocus
                    text: FAQ.fa_save
                    Layout.preferredWidth: height
                }
                Button {
                    font.family: faFontFamily
                    font.styleName: faFontStyle
                    font.pointSize: faPointSize
                    focusPolicy: Qt.NoFocus
                    text: FAQ.fa_file_pdf
                    Layout.preferredWidth: height
                    onReleased: {
                        pdfFileDialog.open()
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
                    currentIndex: 1 // default cmark-gfm
                    focusPolicy: Qt.NoFocus
                    model: MarkDownQt.availableConverters(MarkDownQt.FormatMdUtf8, MarkDownQt.FormatHtmlUtf8)
                    onCurrentIndexChanged: {
                        userMdActivity()
                    }
                }
                Item { // just margin
                    width: 2
                }
            }
        }
        // Source input
        CodeArea {
            id: textIn
            anchors.top: sourceToolBar.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: parent.width / 2
            textArea.focus: true
            textArea.onTextChanged: userMdActivity()
            textArea.onCursorPositionChanged: userMdActivity()
            textArea.font.pointSize: 11 // TODO setting
            KSyntaxHighlighting {
                qmlTextDocument: textIn.textArea.textDocument
                themeName: "Default"
                definitionName: "Markdown"
            }
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
                    font.family: faFontFamily
                    font.styleName: faFontStyle
                    font.pointSize: faPointSize
                    focusPolicy: Qt.NoFocus
                    text: FAQ.fa_home
                    Layout.preferredWidth: height
                    onReleased: {
                        !showOnlineHelp ? userMdActivity(true) : helpViewLoader.item.url = helpUrl
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
                    focusPolicy: Qt.NoFocus
                    model: styleStrings
                    currentIndex: 1 // default Github CSS
                    onCurrentIndexChanged: {
                        userMdActivity()
                    }
                }
                Button {
                    font.family: faFontFamily
                    font.styleName: faFontStyle
                    font.pointSize: faPointSize
                    focusPolicy: Qt.NoFocus
                    text: !showOnlineHelp ? FAQ.fa_question : FAQ.fa_backward
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

            TabsConverted {
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
