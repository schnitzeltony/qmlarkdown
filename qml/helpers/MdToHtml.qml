import QtQuick 2.12
import MarkDownQt 1.0

Item {
    property string strHtml


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

}
