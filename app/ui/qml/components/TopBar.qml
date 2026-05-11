import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import themes 1.0

Rectangle {
    color: Theme.bgPanel

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.spaceM

        // App title
        Text {
            text: "Proximi"
            color: Theme.textPrimary
            font.pixelSize: Theme.fontTitle
            font.bold: true
            Layout.alignment: Qt.AlignVCenter
        }

        // Separator
        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: 24
            Layout.leftMargin: Theme.spaceM
            Layout.rightMargin: Theme.spaceS
            color: Theme.border
        }

        // Selected folder path (truncated)
        Text {
            id: folderPathText
            property string fullPath: typeof scanController !== "undefined" ? scanController.currentFolder : ""
            text: {
                if (!fullPath || fullPath === "") return "No folder selected"
                // Show last 2 segments of path for readability
                var parts = fullPath.replace(/\\/g, "/").split("/")
                if (parts.length > 2) {
                    return ".../" + parts.slice(-2).join("/")
                }
                return fullPath
            }
            color: fullPath ? Theme.textSecondary : Theme.textDisabled
            font.pixelSize: Theme.fontSmall
            elide: Text.ElideMiddle
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }

        // Select Folder button
        Button {
            text: "Select Folder"
            onClicked: {
                if (typeof scanController !== "undefined") {
                    scanController.selectFolder()
                }
            }
            background: Rectangle {
                color: parent.hovered ? Theme.accentHover : Theme.accent
                radius: Theme.radiusS
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            contentItem: Text {
                text: parent.text
                color: Theme.textPrimary
                font.pixelSize: Theme.fontSmall
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        // Scan button
        Button {
            id: scanButton
            text: {
                if (typeof scanController !== "undefined" && scanController.scanState === "scanning") {
                    return "Scanning... " + scanController.scanProgress + "%"
                }
                return "Scan"
            }
            enabled: {
                if (typeof scanController === "undefined") return false
                return scanController.currentFolder !== "" && scanController.scanState !== "scanning"
            }

            onClicked: {
                if (typeof scanController !== "undefined") {
                    scanController.startScan()
                }
            }

            background: Rectangle {
                color: {
                    if (!scanButton.enabled) return Theme.accentDisabled
                    return scanButton.hovered ? Theme.accentHover : Theme.accentSubtle
                }
                radius: Theme.radiusS
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            contentItem: Text {
                text: scanButton.text
                color: scanButton.enabled ? Theme.textPrimary : Theme.textDisabled
                font.pixelSize: Theme.fontSmall
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        Item {
            Layout.preferredWidth: Theme.spaceS
        }

        // Settings icon placeholder
        Text {
            text: "⚙"
            color: Theme.textSecondary
            font.pixelSize: Theme.fontTitle
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
