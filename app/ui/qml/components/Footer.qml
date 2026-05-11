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
            text: typeof scanController !== "undefined" && scanController.scanState === "scanning"
                  ? "Scanning..."
                  : "Ready"
            color: Theme.textSecondary
            font.pixelSize: Theme.fontCaption
            Layout.alignment: Qt.AlignVCenter
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
}
