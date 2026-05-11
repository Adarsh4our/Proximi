import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import themes 1.0

Item {
    id: loadingRoot

    property int currentCount: 0
    property int totalCount: 0
    property int progressPercent: 0

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Theme.spaceM
        width: Math.min(parent.width * 0.5, 320)

        // Pulsing indicator
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 48
            Layout.preferredHeight: 48
            radius: 24
            color: Theme.accent
            opacity: pulseAnim.running ? 1.0 : 0.6

            Text {
                anchors.centerIn: parent
                text: "🔍"
                font.pixelSize: 22
            }

            SequentialAnimation on opacity {
                id: pulseAnim
                running: true
                loops: Animation.Infinite
                NumberAnimation { to: 0.4; duration: 800; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
            }
        }

        // Scanning text
        Text {
            text: "Scanning images..."
            color: Theme.textPrimary
            font.pixelSize: Theme.fontHeader
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }

        // Progress text
        Text {
            text: loadingRoot.totalCount > 0
                  ? loadingRoot.currentCount + " of " + loadingRoot.totalCount + " images"
                  : "Discovering files..."
            color: Theme.textSecondary
            font.pixelSize: Theme.fontBody
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }

        // Progress bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 4
            radius: 2
            color: Theme.bgHover

            Rectangle {
                width: parent.width * (loadingRoot.progressPercent / 100)
                height: parent.height
                radius: 2
                color: Theme.accent

                Behavior on width {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }
            }
        }

        // Percentage text
        Text {
            text: loadingRoot.progressPercent + "%"
            color: Theme.textMuted
            font.pixelSize: Theme.fontSmall
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }
    }
}
