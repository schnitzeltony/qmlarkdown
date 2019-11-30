import QtQuick 2.12
import QtQuick.Controls 2.12

Flickable {
    id: flickableItem
    // public property
    property alias textArea: textArea
    property alias text: textArea.text
    property alias textDocument: textArea.textDocument
    // public method
    function startScrollTo(position) {
        textArea.bCursorPosChangedByExtern = true
        textArea.iLastPosition = position
        textArea.cursorPosition = position
    }

    // private
    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AlwaysOn
    }
    ScrollBar.horizontal: ScrollBar {
        policy: ScrollBar.AlwaysOn
    }
    contentWidth: textArea.contentWidth
    contentHeight: textArea.contentHeight
    clip: true
    TextArea {
        id: textArea
        readOnly: true
        wrapMode: Text.WordWrap
        selectByMouse: true
        selectByKeyboard: true
        persistentSelection: true
        focus: true
        property bool bCursorPosChangedByExtern: false
        property int iLastPosition: 0

        onCursorRectangleChanged: {
            if(bCursorPosChangedByExtern) {
                flickableItem.contentY = cursorRectangle.y
                bCursorPosChangedByExtern = false
            }
        }
        onContentHeightChanged: {
            flickableItem.startScrollTo(iLastPosition)
        }
    }
}
