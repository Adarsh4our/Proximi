import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import themes 1.0

Rectangle {
    color: Theme.bgSidebar

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spaceM
        spacing: Theme.spaceS

        // Section header
        Text {
            text: "Library"
            color: Theme.textMuted
            font.pixelSize: Theme.fontSmall
            font.bold: true
            font.letterSpacing: 1.2
            Layout.bottomMargin: Theme.spaceXS
        }

        // All Photos nav item
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: Theme.radiusS
            color: Theme.accent

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spaceS
                anchors.rightMargin: Theme.spaceS
                spacing: Theme.spaceS

                Text {
                    text: "🖼"
                    font.pixelSize: Theme.fontBody
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: "All Photos"
                    color: Theme.textPrimary
                    font.pixelSize: Theme.fontBody
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }

                // Image count badge
                Rectangle {
                    visible: typeof scanController !== "undefined" && scanController.scannedCount > 0
                    Layout.preferredWidth: countLabel.implicitWidth + Theme.spaceS * 2
                    Layout.preferredHeight: 20
                    radius: 10
                    color: Theme.accentHover

                    Text {
                        id: countLabel
                        anchors.centerIn: parent
                        text: typeof scanController !== "undefined" ? scanController.scannedCount : "0"
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontCaption
                    }
                }
            }
        }

        // Spacer
        Item {
            Layout.fillHeight: true
        }
    }
}
