import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import themes 1.0

Rectangle {
    color: Theme.bgPanel

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spaceM
        anchors.rightMargin: Theme.spaceM
        spacing: Theme.spaceS

        Text {
            text: {
                if (toastTimer.running) return toastText
                return typeof scanController !== "undefined" && scanController.scanState === "scanning"
                  ? "Scanning..."
                  : "Ready"
            }
            color: toastTimer.running ? Theme.accent : Theme.textSecondary
            font.pixelSize: Theme.fontCaption
            font.bold: toastTimer.running
            Layout.alignment: Qt.AlignVCenter
            
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        Item {
            Layout.fillWidth: true
        }

        Text {
            text: {
                if (typeof scanController === "undefined") return ""
                var count = scanController.scannedCount
                return count > 0 ? count + " images" : ""
            }
            color: Theme.textMuted
            font.pixelSize: Theme.fontCaption
            Layout.alignment: Qt.AlignVCenter
        }
    }
    
    property string toastText: ""
    
    Timer {
        id: toastTimer
        interval: 2000
        repeat: false
    }
    
    Connections {
        target: typeof cleanupController !== "undefined" ? cleanupController : null
        function onActionCompleted(msg) {
            toastText = msg
            toastTimer.restart()
        }
    }
}
