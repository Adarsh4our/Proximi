import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import themes 1.0

Rectangle {
    id: footerRoot
    color: Theme.bgGlass

    // Top glow line
    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: 1
        color: Theme.accentGlow
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spaceM
        anchors.rightMargin: Theme.spaceM
        spacing: Theme.spaceS

        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: 6

            // Pulsing dot indicator
            Rectangle {
                width: 8
                height: 8
                radius: 4
                color: Theme.accent
                anchors.verticalCenter: parent.verticalCenter
                visible: typeof scanController !== "undefined" && scanController.scanState === "scanning"

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: visible
                    NumberAnimation { from: 0.3; to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1.0; to: 0.3; duration: 800; easing.type: Easing.InOutSine }
                }
            }

            Text {
                text: {
                    return typeof scanController !== "undefined" && scanController.scanState === "scanning"
                      ? "Scanning..."
                      : "Ready"
                }
                color: Theme.textSecondary
                font.pixelSize: Theme.fontCaption
                font.family: Theme.fontFamily
                anchors.verticalCenter: parent.verticalCenter
            }
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
            font.family: Theme.fontFamily
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // ── Animated Toast Notification ────────────────────────────────────
    property string toastText: ""
    property bool toastVisible: false

    Timer {
        id: toastTimer
        interval: 2500
        repeat: false
        onTriggered: footerRoot.toastVisible = false
    }

    Connections {
        target: typeof cleanupController !== "undefined" ? cleanupController : null
        function onActionCompleted(msg) {
            footerRoot.toastText = msg
            footerRoot.toastVisible = true
            toastTimer.restart()
        }
    }

    // Floating toast pill — slides up from footer
    Rectangle {
        id: toastPill
        anchors.horizontalCenter: parent.horizontalCenter
        y: footerRoot.toastVisible ? -height - 10 : 0
        width: toastLabel.implicitWidth + 48
        height: 36
        radius: 18
        color: Theme.bgPanel
        border.color: Theme.accent
        border.width: 1
        opacity: footerRoot.toastVisible ? 1.0 : 0.0
        visible: opacity > 0
        z: 100

        // Accent glow behind pill
        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            radius: parent.radius + 2
            color: "transparent"
            border.width: 2
            border.color: Theme.glowAccent
            opacity: 0.5
        }

        Row {
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: "✓"
                color: Theme.success
                font.bold: true
                font.pixelSize: Theme.fontBody
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                id: toastLabel
                text: footerRoot.toastText
                color: Theme.textPrimary
                font.bold: true
                font.pixelSize: Theme.fontSmall
                font.family: Theme.fontFamily
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Behavior on y {
            NumberAnimation { duration: Theme.animPage; easing.type: Easing.OutBack }
        }
        Behavior on opacity {
            NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic }
        }
    }
}
