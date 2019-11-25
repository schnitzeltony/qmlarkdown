import QtQuick 2.12
import QtQuick.Controls 2.12

ScrollView {
    property alias text: textArea.text
    property alias cursorPosition: textArea.cursorPosition
    function forceActiveFocus() { textArea.forceActiveFocus() }

    padding: 8
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOn //AsNeeded
    ScrollBar.vertical.policy: ScrollBar.AlwaysOn
    clip: true
    TextArea {
        id: textArea
        wrapMode: TextEdit.NoWrap
        selectByMouse: true
        cursorDelegate: inputCursorDelegate

        // custom cursor
        Component {
            id: inputCursorDelegate
            Rectangle {
                height: textArea.cursorRectangle.height
                width: 2;
                color: "black";
                visible: parent.cursorVisible
                SequentialAnimation on opacity { running: true; loops: Animation.Infinite
                    NumberAnimation { to: 0; duration: 300 }
                    NumberAnimation { to: 1; duration: 300 }
                }
            }
        }
        // grey box for current line
        Rectangle {
            y: textArea.cursorRectangle.y
            height: textArea.cursorRectangle.height
            width: textArea.width - 16
            anchors.left: textArea.left
            anchors.leftMargin: 8
            opacity: 0.05
            color: "#1b1f23"
        }
    }
}
