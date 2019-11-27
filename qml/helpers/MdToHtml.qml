import QtQuick 2.12
import MarkDownQt 1.0

Item {
    // To be set by consumer
    property string projectPath
    property int userActiveIntervall
    property int minUpdateIntervall
    // To be called by consumer
    function userActivityHandler(strMd, iPosition, bGithubStyle) {
        if(strMd !== privateStuff.strCurrentMd ||
                iPosition !== privateStuff.iCurrentPosition ||
                )
        privateStuff.bCurrentGithubStyle = bGithubStyle
        userInputTimer.restart()
        if(!minUpdateTimer.running) {
            minUpdateTimer.start()
        }
    }

    // output
    property string strHtml

    // private
    Item {
        id: privateStuff
        property string strTagInjected: ""
        property bool bScrollTop: false

        property bool bCurrentGithubStyle: false
        property int iCurrentPosition: 0
        property string strCurrentMd: ""

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

        function convertToHtml(dataIn, bGithubStyle) {
            var currentConvert = comboConvert.model[comboConvert.currentIndex]
            var dataHtml = MarkDownQt.convert(currentConvert, MarkDownQt.FormatMdUtf8, MarkDownQt.FormatHtmlUtf8, dataIn)
            // prepend style
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
                lineEnd = htmlHelper.findAnchorInjectPosition(text, pos)
                var linesUp = settings.autoScrollTopLinesMargin+1
                while(lineEnd > 0 && linesUp > 0) {
                    pos = text.lastIndexOf("\n", lineEnd-1);
                    lineEnd = htmlHelper.findAnchorInjectPosition(text, pos)
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
            var strBaseUrl = "file://" + projectPath
            // append trailing '/'
            if(strBaseUrl.substring(strBaseUrl.length-1, strBaseUrl.length) !== "/") {
                strBaseUrl += "/"
            }

            // convert MD -> HTML
            // Note: this might look odd but:
            // * HTML quirks are done most easily with UTF-8 encoded text
            // * convertToHtml expects javascript arraybuffer
            // => convert back & forth
            var strHtml = QtHelper.utf8DataToStr(htmlHelper.convertToHtml(QtHelper.strToUtf8Data(injText), isGithubStyle()))

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
    }
}
