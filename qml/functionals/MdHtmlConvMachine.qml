import QtQuick 2.12
import MarkDownQt 1.0
import QtHelper 1.0
import Qt.labs.settings 1.0

Item {
    // public write properties
    // public read properties
    property string propertyStrHtmlBare: ""
    property string propertyStrHtmlWithSearchTag: ""
    property bool propertyBScrollTop: false
    property string propertyStrSearchTagInjected: ""
    property int propertyIHtmlPosition: 0
    readonly property string propertyStrSearchString: "__qmlark_search_tag__"
    // signals
    signal conversionDone(var bHtmlBareChange, var bHtmlPositionChange, var bHtmlStyleChange)
    // public methods
    function userMdActivity(strMd, strConvertLib, bGithubStyle, iPosition) {
        return privateItem.userMdActivity(strMd, strConvertLib, bGithubStyle, iPosition)
    }
    function convertToHtml(strMd, strConvertLib, bGithubStyle) {
        return privateItem.convertToHtml(strMd, strConvertLib, bGithubStyle, false)
    }

    // private
    Item {
        id: privateItem
        function userMdActivity(strMd, strConvertLib, bGithubStyle, iPosition) {
            // invalid conversion lib: bail out
            if(!strConvertLib)
                return
            // Check for changes
            if(strMd !== privateItem.strCurrentMd) {
                privateItem.strCurrentMd = strMd
                privateItem.bHtmlBareChange = true
            }
            if(bGithubStyle !== privateItem.bCurrentGithubStyle) {
                privateItem.bCurrentGithubStyle = bGithubStyle
                privateItem.bHtmlStyleChange = true
            }
            if(iPosition !== privateItem.iCurrentPosition) {
                privateItem.iCurrentPosition = iPosition
                // don't eat up our rate limit on github by movong around position
                if(strConvertLib !== "github-online") {
                    privateItem.bHtmlPositionChange = true;
                }
            }
            if(strConvertLib !== privateItem.strCurrentConvertLib) {
                privateItem.strCurrentConvertLib = strConvertLib
                privateItem.bHtmlBareChange = true
            }

            // conversion required?
            if(privateItem.bHtmlBareChange ||
                    privateItem.bHtmlPositionChange ||
                    privateItem.bHtmlStyleChange) {
                userInputTimer.restart()
                if(!minUpdateTimer.running) {
                    minUpdateTimer.start()
                }
            }
        }
        function convertToHtml(strMd, strConvertLib, bGithubStyle, bKeepBareHtml) {
            var dataHtml
            var dataInUtf8 = QtHelper.strToUtf8Data(strMd)
            dataHtml = MarkDownQt.convert(strConvertLib, MarkDownQt.FormatMdUtf8, MarkDownQt.FormatHtmlUtf8, dataInUtf8)
            if(bKeepBareHtml) {
                privateItem.dataLastBareHtml = dataHtml
            }

            // a bit of a hack but better than converting twice
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
            // inject id tag for auto scroll at the end of previous line
            var pos = iCurrentPosition
            var lineEnd = 0
            var idStr = '<a id="' + propertyStrSearchString  + '"></a>'

            // auto follow does not work on github
            if(privateItem.strCurrentConvertLib !== "github-online") {
                // find appropriate position for search tag
                lineEnd = findAnchorInjectPosition(strCurrentMd, pos)
                var linesUp = settings.autoScrollTopLinesMargin+1
                while(lineEnd > 0 && linesUp > 0) {
                    pos = strCurrentMd.lastIndexOf("\n", lineEnd-1);
                    lineEnd = findAnchorInjectPosition(strCurrentMd, pos)
                    linesUp--
                }
            }
            var bScrollTop = false
            var strMdWithInjTag
            var strSearchTagInjected = ""
            if(lineEnd > 0) {
                var txtLead = strCurrentMd.substring(0, lineEnd)
                var txtTrail = strCurrentMd.substring(lineEnd)
                strSearchTagInjected = idStr
                strMdWithInjTag = txtLead + " " + strSearchTagInjected + txtTrail
            }
            else {
                strMdWithInjTag = strCurrentMd
                if(lineEnd === 0) {
                    bScrollTop = true
                }
            }

            // convert MD -> HTML (!!avoid writing external vars more than necessary)
            var strHtmlWithSearchTag = QtHelper.utf8DataToStr(convertToHtml(strMdWithInjTag, privateItem.strCurrentConvertLib, bCurrentGithubStyle, true))
            var iHtmlPosition = 0
            if(strSearchTagInjected !== "") {
                // hack away quoted anchors
                strHtmlWithSearchTag = strHtmlWithSearchTag.replace('&lt;a id=&quot;'+propertyStrSearchString+'&quot;&gt;&lt;/a&gt;', idStr)
                iHtmlPosition = strHtmlWithSearchTag.indexOf(idStr);
            }
            if(bScrollTop) {
                iHtmlPosition = 0
            }
            // now set public properties in one row
            propertyStrHtmlBare = QtHelper.utf8DataToStr(privateItem.dataLastBareHtml)
            propertyStrHtmlWithSearchTag = strHtmlWithSearchTag
            propertyBScrollTop = bScrollTop
            propertyStrSearchTagInjected = strSearchTagInjected
            propertyIHtmlPosition = iHtmlPosition
            // give note
            conversionDone(privateItem.bHtmlBareChange, privateItem.bHtmlPositionChange, privateItem.bHtmlStyleChange)
            privateItem.bHtmlBareChange = false
            privateItem.bHtmlPositionChange = false
            privateItem.bHtmlStyleChange = false
        }

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

        property bool bHtmlBareChange : false
        property bool bHtmlPositionChange : false
        property bool bHtmlStyleChange : false

        property var dataLastBareHtml

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
    }
}
