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
import "qrc:/qml/helpers" as HELPERS
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
        property int autoScrollTopLinesMargin: 0
        property string helpUrl: "https://commonmark.org/help/"
        property int userActiveIntervall: 100
        property int minUpdateIntervall: 300
    }

    HELPERS.MdToHtml {
        id: htmlHelper
        projectPath: projectPath.text
        userActiveIntervall: settings.userActiveIntervall
        minUpdateIntervall: settings.minUpdateIntervall
    }

    readonly property var styleStrings: [qsTr("Default Style"), qsTr("QT/QML Label Style"), qsTr("Github CSS"), qsTr("HTML"), qsTr("HTML Github CSS")]
    function isQtLabelBoxVisible() {
        return comboStyle.currentIndex === 1
    }
    function isHtmlSourceVisible() {
        return comboStyle.currentIndex === 3 || comboStyle.currentIndex === 4
    }
    function isHtmlViewVisible() {
        return comboStyle.currentIndex === 0 || comboStyle.currentIndex === 2
    }
    function isGithubStyle() {
        return comboStyle.currentIndex === 2 || comboStyle.currentIndex === 4
    }

    property string strTagInjected: ""
    property bool bScrollTop: false

    property bool showOnlineHelp: false
    readonly property string helpUrl: settings.helpUrl

    FontLoader {
        source: "qrc:/Font-Awesome/webfonts/fa-solid-900.ttf"
    }

    Timer {
        id: userInputTimer
        interval: settings.userActiveIntervall
        onTriggered: {
            minUpdateTimer.stop()
            _updateHtml()
        }
    }
    Timer {
        id: minUpdateTimer
        interval: settings.minUpdateIntervall
        onTriggered: {
            userInputTimer.stop()
            _updateHtml()
        }
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
            var dataHtml = htmlHelper.convertToHtml(QtHelper.strToUtf8Data(textIn.text), isGithubStyle())
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
                    onPressed: {
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
                        userActivityHandler()
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
            onTextChanged: userActivityHandler()
            onCursorPositionChanged: {
                // don't eat up our rate limit on github...
                if(comboConvert.model[comboConvert.currentIndex] !== "github-online") {
                    userActivityHandler()
                }
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
                    font.family: "Font Awesome 5 Free"
                    font.pointSize: 16
                    text: FA_SOLID.icon(FA_SOLID.fa_solid_900_home)
                    Layout.preferredWidth: height
                    onPressed: {
                        !showOnlineHelp ? userActivityHandler() : helpViewLoader.item.url = helpUrl
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
                            userActivityHandler()
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
                        userActivityHandler()
                        textIn.forceActiveFocus()
                    }
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
        // Qt label view
        Label {
            id: qtLabelView
            anchors.top: htmlToolBar.bottom
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            width: parent.width / 2
            visible: isQtLabelBoxVisible() && !showOnlineHelp
        }
        // HtmlSource view
        ScrollView {
            anchors.top: htmlToolBar.bottom
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            width: parent.width / 2
            visible: isHtmlSourceVisible() && !showOnlineHelp
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOn //AsNeeded
            ScrollBar.vertical.policy: ScrollBar.AlwaysOn
            TextArea {
                id: htmlSourceView
                readOnly: true
                wrapMode: Text.WordWrap
                selectByMouse: true
                selectByKeyboard: true
            }
        }
        // Html view
        SwipeView {
            id: swipeHtml
            anchors.top: htmlToolBar.bottom
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            width: parent.width / 2
            clip: true
            currentIndex: showOnlineHelp ? 1 : 0
            visible: (!isQtLabelBoxVisible() && !isHtmlSourceVisible()) || showOnlineHelp
            interactive: false
            WebEngineView {
                id: webView
                onContextMenuRequested: function(request) {
                    request.accepted = true;
                }
                onLoadingChanged: function(loadRequest) {
                    if(loadRequest.errorCode === 0 &&
                            loadRequest.status === WebEngineLoadRequest.LoadSucceededStatus) {
                        if(window.bScrollTop) {
                            runJavaScript('document.body.scrollTop = 0; document.documentElement.scrollTop = 0;')
                        }
                        else if (window.strTagInjected !== '') {
                            runJavaScript('document.getElementById("' + strTagInjected +'").scrollIntoView(true);')
                        }
                    }
                }
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
