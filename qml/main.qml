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
import "qrc:/fa-js-wrapper/fa-solid-900.js" as FA_SOLID


ApplicationWindow {
    id: window
    visible: true
    width: 800
    height: 600
    visibility: "Maximized"
    title: qsTr("Simple WYSIWYG MarkDown editor")

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


    function findAnchorInjectPosition(text, pos) {
        var validPosFound = false
        var lastLineEnd
        var lineEnd
        do {
            lastLineEnd = text.lastIndexOf("\n", pos);
            lineEnd = text.indexOf("\n", pos);
            if(lastLineEnd < lineEnd) {
                var strLine =  text.substring(lastLineEnd+1, lineEnd).trim()
                // we cannot append our anchor at special lines (TODO add more?)
                var blackList = ['---','```','***'];
                validPosFound = true
                blackList.forEach(function(item, index, array) {
                    var blackPos = strLine.indexOf(item)
                    if(blackPos === 0) {
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

    function convertToHtml(dataIn) {
        var currentConvert = comboConvert.model[comboConvert.currentIndex]
        var dataHtml = MarkDownQt.convert(currentConvert, MarkDownQt.FormatMdUtf8, MarkDownQt.FormatHtmlUtf8, dataIn)
        // prepend style
        var bGithubStyle = isGithubStyle()
        if(bGithubStyle) {
            dataHtml = MarkDownQt.convert("github-markdown-css", MarkDownQt.FormatHtmlUtf8, MarkDownQt.FormatHtmlUtf8, dataHtml)
        }
        // framing (header / footer)
        if(bGithubStyle) {
            dataHtml = MarkDownQt.addFraming("github-markdown-css", MarkDownQt.FormatHtmlUtf8, dataHtml)
        }
        else {
            dataHtml = MarkDownQt.addFraming(currentConvert, MarkDownQt.FormatHtmlUtf8, dataHtml)
        }
        return dataHtml
    }

    function _updateHtml() {
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
            var linesUp = settings.autoScrollTopLinesMargin+1
            while(lineEnd > 0 && linesUp > 0) {
                pos = text.lastIndexOf("\n", lineEnd-1);
                lineEnd = findAnchorInjectPosition(text, pos)
                linesUp--
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
        var strBaseUrl = "file://" + projectPath.text
        // append trailing '/'
        if(strBaseUrl.substring(strBaseUrl.length-1, strBaseUrl.length) !== "/") {
            strBaseUrl += "/"
        }

        // convert MD -> HTML
        // Note: this might look odd but:
        // * HTML quirks are done most easily with UTF-8 encoded text
        // * convertToHtml expects javascript arraybuffer
        // => convert back & forth
        var strHtml = QtHelper.utf8DataToStr(convertToHtml(QtHelper.strToUtf8Data(injText)))

        if(window.strTagInjected !== "") {
            // hack away quoted anchors
            strHtml = strHtml.replace('&lt;a id=&quot;'+strTag+'&quot;&gt;&lt;/a&gt;', idStr)
        }
        // load all our frames' contents
        if(isHtmlViewVisible()) {
            webView.loadHtml(strHtml, strBaseUrl)
        }
        if(isQtLabelBoxVisible()) {
            qtLabelView.text = strHtml
        }
        if(isHtmlSourceVisible()) {
            htmlSourceView.text = strHtml
        }
    }

    function userActivityHandler() {
        userInputTimer.restart()
        if(!minUpdateTimer.running) {
            minUpdateTimer.start()
        }
    }

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
                        textIn.tryExportPdf()
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
                    focus: true
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
        ScrollView {
            anchors.top: sourceToolBar.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: parent.width / 2
            padding: 8
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOn //AsNeeded
            ScrollBar.vertical.policy: ScrollBar.AlwaysOn
            clip: true
            TextArea {
                id: textIn
                wrapMode: TextEdit.NoWrap
                selectByMouse: true
                onTextChanged: userActivityHandler()
                cursorDelegate: inputCursorDelegate
                onCursorPositionChanged: {
                    // don't eat up our rate limit on github...
                    if(comboConvert.model[comboConvert.currentIndex] !== "github-online") {
                        userActivityHandler()
                    }
                }
                function tryExportPdf() {
                    pdfFileDialog.open()
                }
                // custom cursor
                Component {
                    id: inputCursorDelegate
                    Rectangle {
                        height: textIn.cursorRectangle.height
                        width: 2;
                        color: "black";
                        visible: parent.cursorVisible
                        SequentialAnimation on opacity { running: true; loops: Animation.Infinite
                            NumberAnimation { to: 0; duration: 300 }
                            NumberAnimation { to: 1; duration: 300 }
                        }
                    }
                }
                Rectangle {
                    y: textIn.cursorRectangle.y
                    height: textIn.cursorRectangle.height
                    width: textIn.width - 16
                    anchors.left: textIn.left
                    anchors.leftMargin: 8
                    opacity: 0.05
                    color: "#1b1f23"
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
                        var dataHtml = convertToHtml(QtHelper.strToUtf8Data(textIn.text))
                        if(MarkDownQt.convertToFile("qtwebenginepdf", MarkDownQt.FormatHtmlUtf8, MarkDownQt.FormatPdfBin, dataHtml, fileName)) {
                            console.log("PDF " + fileName + "created")
                        }
                        else {
                            console.error()("PDF " + fileName + "not created!")
                        }

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
