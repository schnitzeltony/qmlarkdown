import QtQuick 2.12
import QtQuick.Controls 2.12
import QtWebEngine 1.8
import Qt.labs.settings 1.0
import KSyntaxHighlighting 1.0
import "qrc:/qml/controls" as CTRLS

Item {
    // public write properties
    property var propertyHtmlConverter
    // public methods
    function handleNewHtmlData(bHtmlBareChange, bHtmlPositionChange, bHtmlStyleChange) {
        return swipeViewConverted.newHtmlData(bHtmlBareChange, bHtmlPositionChange, bHtmlStyleChange)
    }

    // private
    Settings {
        id: settings
        property alias currentTab: swipeViewConverted.currentIndex
    }
    // converted display variants - see tabs
    SwipeView {
        id: swipeViewConverted
        width: parent.width
        anchors.top: parent.top
        anchors.bottom: tabBarConverted.top
        currentIndex: tabBarConverted.currentIndex

        function newHtmlData(bHtmlBareChange, bHtmlPositionChange, bHtmlStyleChange) {
            switch(currentIndex) {
            case 0: // web
                var strBaseUrl = "file://" + projectPath.text
                // append trailing '/'
                if(strBaseUrl.substring(strBaseUrl.length-1, strBaseUrl.length) !== "/") {
                    strBaseUrl += "/"
                }
                webView.loadHtml(propertyHtmlConverter.propertyStrHtmlWithSearchTag, strBaseUrl)
                break;
            case 1: // qt
                if(bHtmlBareChange) {
                    qtLabelView.text = propertyHtmlConverter.propertyStrHtmlBare
                }
                break;
            case 2: // source
                if(bHtmlBareChange || bHtmlStyleChange) {
                    if(propertyHtmlConverter.propertyStrSearchTagInjected === "") {
                        htmlSourceView.text =  propertyHtmlConverter.propertyStrHtmlWithSearchTag
                    }
                    else {
                        htmlSourceView.text = propertyHtmlConverter.propertyStrHtmlWithSearchTag.replace(propertyHtmlConverter.propertyStrSearchTagInjected, "")
                    }
                }
                if(bHtmlPositionChange || bHtmlStyleChange) {
                    htmlSourceView.startScrollTo(propertyHtmlConverter.propertyIHtmlPosition)
                }
                break;
            }
        }
        onCurrentIndexChanged: {
            newHtmlData(true, true, true)
            textIn.forceActiveFocus()
        }
        spacing: 10
        // Html view
        WebEngineView {
            id: webView
            onContextMenuRequested: function(request) {
                request.accepted = true;
            }
            onLoadingChanged: function(loadRequest) {
                if(loadRequest.errorCode === 0 &&
                        loadRequest.status === WebEngineLoadRequest.LoadSucceededStatus) {
                    if(propertyHtmlConverter.propertyBScrollTop) {
                        runJavaScript('document.body.scrollTop = 0; document.documentElement.scrollTop = 0;')
                    }
                    else if (propertyHtmlConverter.propertyStrSearchTagInjected !== "") {
                        runJavaScript('document.getElementById("' + propertyHtmlConverter.propertyStrSearchString +'").scrollIntoView(true);')
                    }
                }
            }
        }
        // Qt label view
        Label {
            id: qtLabelView
            wrapMode: Text.WordWrap
        }
        // HtmlSourceCode view
        CTRLS.ScrolledTextOut {
            id: htmlSourceView
            MouseArea {
                acceptedButtons: Qt.RightButton
                anchors.fill: parent
                onClicked: contextMenuHtml.popup()
            }
            KSyntaxHighlighting {
                qmlTextDocument: htmlSourceView.textDocument
                themeName: "Default"
                definitionName: "HTML"
            }
        }
    }
    CTRLS.ContextMenuBase {
        id: contextMenuHtml
        targetItem: htmlSourceView.textArea
    }
    TabBar {
        id: tabBarConverted
        width: parent.width
        anchors.bottom: parent.bottom
        currentIndex: swipeViewConverted.currentIndex
        contentHeight: 32
        TabButton {
            id: tabWebView
            text: qsTr("Web view")
        }
        TabButton {
            id: tabQtView
            text: qsTr("Qt/QML control")
        }
        TabButton {
            id: tabSourceView
            text: qsTr("Html source")
        }
    }
}
