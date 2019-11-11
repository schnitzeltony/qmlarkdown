import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.VirtualKeyboard 2.4
import QtQuick.Window 2.12
import QtQuick.Controls.Material 2.12
import QtWebEngine 1.8
import QtQuick.Layouts 1.12
import Qt.labs.settings 1.0

import MarkDownQt 1.0
import "qrc:/fa-js-wrapper/fa-solid-900.js" as FA_SOLID


ApplicationWindow {
    id: window
    visible: true
    width: 800
    height: 600
    visibility: "Maximized"
    title: qsTr("Simple WYSIWYG MarkDown editor")

    // TODO: enum use here and for CMark
    property var styleStrings: [qsTr("Default Style"), qsTr("QT/QML Label Style"), qsTr("Github Style"), qsTr("HTML source")]
    property bool showQtLabelBox: comboStyle.currentIndex === 1
    property bool showHtmlSourceBox: comboStyle.currentIndex === 3
    property string strTagInjected: ""
    property bool bScrollTop: false
    // TODO: Qt 5.14 introduced QTextDocument::setMarkdown - add optional support later

    property bool showOnlineHelp: false
    readonly property string helpUrl: settings.helpUrl

    function findAnchorInjectPosition(text, pos) {
        var validPosFound = false
        var lastLineEnd
        var lineEnd
        do {
            lastLineEnd = text.lastIndexOf("\n", pos);
            lineEnd = text.indexOf("\n", pos);
            if(lastLineEnd < lineEnd) {
                var strLine =  text.substring(lastLineEnd+1, lineEnd)
                // we cannot appand our anchor at special lines (TODO add more?)
                var blackList = ['---','```'];
                validPosFound = true
                blackList.forEach(function(item, index, array) {
                    var blackPos = text.indexOf(item, lastLineEnd+1)
                    if(blackPos === lastLineEnd+1) {
                        validPosFound = false
                    }
                })
            }
            if(!validPosFound && lastLineEnd > 0) {
                pos = lastLineEnd-1
            }
        } while (!validPosFound && lastLineEnd > 0)
        // top position?
        if(lastLineEnd < 0) {
            lineEnd = 0
            validPosFound = true
        }
        // no matching line found
        if(!validPosFound) {
            lineEnd = -1
        }
        return lineEnd
    }

    function updateHtml() {
        // reset worker properties
        window.bScrollTop = false
        window.strTagInjected = ""

        // inject id tag for auto scroll at the end of previous line
        var pos = textIn.cursorPosition
        var text = textIn.text
        var lineEnd = 0
        var strTag = 'o2_ueala5b9aiii'
        var idStr = '<a id="' + strTag  + '"></a>'

        // auto follow does not work on github
        if(comboConvert.model[comboConvert.currentIndex] !== "github-online") {
            lineEnd = findAnchorInjectPosition(text, pos)
            if(lineEnd > 0) {
                pos = text.lastIndexOf("\n", lineEnd-1);
                lineEnd = findAnchorInjectPosition(text, pos)
            }
        }
        var injText
        if(lineEnd > 0) {
            var txtLead = text.substring(0, lineEnd)
            var txtTrail = text.substring(lineEnd)
            injText = txtLead + " " + idStr + txtTrail
            window.strTagInjected = strTag
        }
        else {
            injText = text
            if(lineEnd === 0) {
                window.bScrollTop = true
            }
        }

        // baseUrl
        var strBaseUrl = baseUrl.text
        // append trailing '/'
        if(strBaseUrl.substring(strBaseUrl.length-1, strBaseUrl.length) !== "/") {
            strBaseUrl += "/"
        }
        // convert
        var currentConvert = comboConvert.model[comboConvert.currentIndex]
        var strHtml = MarkDownQt.doConvert(injText, currentConvert, MarkDownQt.FormatMd, MarkDownQt.FormatHtml)
        // prepend style
        var githubStyle = comboStyle.currentIndex === 2
        if(githubStyle) {
            strHtml = MarkDownQt.doConvert(strHtml, "github-markdown-css", MarkDownQt.FormatHtml, MarkDownQt.FormatHtml)
        }
        // framing (header / footer)
        if(githubStyle) {
            strHtml = MarkDownQt.addFraming(strHtml, "github-markdown-css", MarkDownQt.FormatHtml)
        }
        else {
            strHtml = MarkDownQt.addFraming(strHtml, currentConvert, MarkDownQt.FormatHtml)
        }
        // hack away quoted anchors
        if(window.strTagInjected !== "") {
            strHtml = strHtml.replace('&lt;a id=&quot;'+strTag+'&quot;&gt;&lt;/a&gt;', idStr)
        }
        // load all our frames' contents
        webView.loadHtml(strHtml, strBaseUrl)
        qtLabelView.text = strHtml
        htmlSourceView.text = strHtml
    }

    Settings {
        id: settings
        // interactive
        property alias baseUrl: baseUrl.text
        property alias style: comboStyle.currentIndex
        property alias convertType: comboConvert.currentIndex
        // non-interactive
        property string helpUrl: "https://commonmark.org/help/"
        property int userActiveIntervall: 300
    }

    FontLoader {
        source: "qrc:/Font-Awesome/webfonts/fa-solid-900.ttf"
    }

    Timer {
        id: userInputTimer
        interval: settings.userActiveIntervall;
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
                    model: MarkDownQt.availableConverters(MarkDownQt.FormatMd, MarkDownQt.FormatHtml)
                    onCurrentIndexChanged: updateHtml()
                }
                Item { // just margin
                    width: 2
                }
            }
        }
        // Source input
        ScrollView {
            anchors.top: sourceToolBar.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: parent.width / 2
            padding: 8
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOn //AsNeeded
            ScrollBar.vertical.policy: ScrollBar.AlwaysOn
            TextArea {
                id: textIn
                wrapMode: TextEdit.NoWrap
                onTextChanged: userInputTimer.restart()
                onCursorPositionChanged: {
                    // don't eat up our rate limit on github...
                    if(comboConvert.model[comboConvert.currentIndex] !== "github-online") {
                        userInputTimer.restart()
                    }
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
                    id: baseUrl
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
        // Qt label view
        Label {
            id: qtLabelView
            anchors.top: htmlToolBar.bottom
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            width: parent.width / 2
            visible: showQtLabelBox && !showOnlineHelp
        }
        // HtmlSource view
        ScrollView {
            anchors.top: htmlToolBar.bottom
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            width: parent.width / 2
            visible: showHtmlSourceBox && !showOnlineHelp
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOn //AsNeeded
            ScrollBar.vertical.policy: ScrollBar.AlwaysOn
            TextArea {
                id: htmlSourceView
                readOnly: true
                wrapMode: Text.WordWrap
                selectByMouse: true
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
            visible: (!showQtLabelBox && !showHtmlSourceBox) || showOnlineHelp
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
