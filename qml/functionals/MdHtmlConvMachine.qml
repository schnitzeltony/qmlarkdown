import QtQuick 2.12
import MarkDownQt 1.0
import QtHelper 1.0
import Qt.labs.settings 1.0

Item {
    // public write properties
    property string projectPath
    // public read properties
    property string strHtml: ""
    property string strHtmlWithSearchTag: ""
    property bool bScrollTop: false
    property bool bSearchTagInjected: false
    property int iHtmlPosition: 0
    readonly property string strSearchString: "__qmlark_search_tag__"
    // public methods
    function userMdActivity(strMd, strConvertLib, bGithubStyle, iPosition) {
        // invalid conversion lib: bail out
        if(!strConvertLib)
            return
        var bHtmlContentChange = false
        var bHtmlPositionChange = false
        // Check for changes
        if(strMd !== privateItem.strCurrentMd) {
            privateItem.strCurrentMd = strMd
            bHtmlContentChange = true
        }
        if(bGithubStyle !== privateItem.bCurrentGithubStyle) {
            privateItem.bCurrentGithubStyle = bGithubStyle
            bHtmlContentChange = true
        }
        if(iPosition !== privateItem.iCurrentPosition) {
            privateItem.iCurrentPosition = iPosition
            bHtmlPositionChange = true;
        }
        if(strConvertLib !== privateItem.strCurrentConvertLib) {
            privateItem.strCurrentConvertLib = strConvertLib
            bHtmlContentChange = true
        }
        // not a position change only?
        if(bHtmlContentChange) {
            privateItem.bHtmlContentChange = true;
        }
        else {
            // don't eat up our rate limit on github by movong around position
            if(strConvertLib === "github-online") {
                bHtmlPositionChange = false
            }
        }

        // conversion required?
        if(bHtmlContentChange || bHtmlPositionChange) {
            userInputTimer.start()
            if(!minUpdateTimer.running) {
                minUpdateTimer.start()
            }
        }
    }
    function convertToHtml(strMd, strConvertLib, bGithubStyle) {
        var dataInUtf8 = QtHelper.strToUtf8Data(strMd)
        var dataHtml = MarkDownQt.convert(strConvertLib, MarkDownQt.FormatMdUtf8, MarkDownQt.FormatHtmlUtf8, dataInUtf8)
        // prepend style
        if(bGithubStyle) {
            dataHtml = MarkDownQt.convert("github-markdown-css", MarkDownQt.FormatHtmlUtf8, MarkDownQt.FormatHtmlUtf8, dataHtml)
        }
        // framing (header / footer)
        if(bGithubStyle) {
            dataHtml = MarkDownQt.addFraming("github-markdown-css", MarkDownQt.FormatHtmlUtf8, dataHtml)
        }
        else {
            dataHtml = MarkDownQt.addFraming(strConvertLib, MarkDownQt.FormatHtmlUtf8, dataHtml)
        }
        return dataHtml
    }

    // private
    Item {
        id: privateItem
        Settings {
            id: settings
            // non-interactive
            property int userActiveIntervall: 100
            property int minUpdateIntervall: 300
            property int autoScrollTopLinesMargin: 0
        }

        property string strCurrentMd: ""
        property bool bCurrentGithubStyle: false
        property int iCurrentPosition: 0
        property string strCurrentConvertLib
        property bool bHtmlContentChange: false

        Timer {
            id: userInputTimer
            interval: settings.userActiveIntervall
            onTriggered: {
                minUpdateTimer.stop()
                privateItem.updateHtml()
            }
        }
        Timer {
            id: minUpdateTimer
            interval: settings.minUpdateIntervall
            onTriggered: {
                userInputTimer.stop()
                privateItem.updateHtml()
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

        function updateHtml() {
            // reset worker properties
            bScrollTop = false
            bSearchTagInjected = false

            // inject id tag for auto scroll at the end of previous line
            var pos = iCurrentPosition
            var lineEnd = 0
            var idStr = '<a id="' + strSearchString  + '"></a>'

            // auto follow does not work on github
            if(privateItem.strCurrentConvertLib !== "github-online") {
                lineEnd = findAnchorInjectPosition(strCurrentMd, pos)
                var linesUp = settings.autoScrollTopLinesMargin+1
                while(lineEnd > 0 && linesUp > 0) {
                    pos = strCurrentMd.lastIndexOf("\n", lineEnd-1);
                    lineEnd = findAnchorInjectPosition(strCurrentMd, pos)
                    linesUp--
                }
            }
            var injText
            if(lineEnd > 0) {
                var txtLead = strCurrentMd.substring(0, lineEnd)
                var txtTrail = strCurrentMd.substring(lineEnd)
                injText = txtLead + " " + idStr + txtTrail
                bSearchTagInjected = true
            }
            else {
                injText = strCurrentMd
                if(lineEnd === 0) {
                    bScrollTop = true
                }
            }

            // convert MD -> HTML
            strHtmlWithSearchTag = QtHelper.utf8DataToStr(convertToHtml(injText, privateItem.strCurrentConvertLib, bCurrentGithubStyle))
            if(bSearchTagInjected) {
                // hack away quoted anchors
                strHtmlWithSearchTag = strHtmlWithSearchTag.replace('&lt;a id=&quot;'+strSearchString+'&quot;&gt;&lt;/a&gt;', idStr)
                iHtmlPosition = strHtmlWithSearchTag.indexOf(idStr);
            }
            if(bScrollTop) {
                iHtmlPosition = 0
            }

            if(bHtmlContentChange) {
                strHtml = strHtmlWithSearchTag.replace(idStr, "")
                bHtmlContentChange = false
            }
        }
    }
}
