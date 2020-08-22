import QtQuick.Controls 2.12

Menu {
    property var targetItem
    MenuItem {
        text: qsTr("Copy")
        enabled: targetItem.selectedText
        onTriggered: targetItem.copy()
    }
    MenuItem {
        text: qsTr("Cut")
        enabled: targetItem.selectedText
        visible: !targetItem.readOnly
        height: visible ? implicitHeight : 0
        onTriggered: targetItem.cut()
    }
    MenuItem {
        text: qsTr("Paste")
        enabled: targetItem.canPaste
        visible: !targetItem.readOnly
        height: visible ? implicitHeight : 0
        onTriggered: targetItem.paste()
    }
}
