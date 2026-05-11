import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import themes 1.0

Item {
    id: emptyRoot

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Theme.spaceL
        width: Math.min(parent.width * 0.6, 360)

        // Folder icon
        Text {
            text: "📂"
            font.pixelSize: 64
            Layout.alignment: Qt.AlignHCenter
            opacity: 0.7
        }

        // Title
        Text {
            text: "No images yet"
            color: Theme.textPrimary
            font.pixelSize: Theme.fontTitle
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }

        // Description
        Text {
            text: "Select a folder containing your photos\nto get started with Proximi."
            color: Theme.textSecondary
            font.pixelSize: Theme.fontBody
            horizontalAlignment: Text.AlignHCenter
            lineHeight: 1.5
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // Browse button
        Button {
            text: "Browse Folder"
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 180
            Layout.preferredHeight: 44

            background: Rectangle {
                radius: Theme.radiusM
                color: parent.hovered ? Theme.accentHover : Theme.accent

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            contentItem: Text {
                text: parent.text
                color: Theme.textPrimary
                font.pixelSize: Theme.fontBody
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            onClicked: {
                if (typeof scanController !== "undefined") {
                    scanController.selectFolder()
                }
            }
        }
    }
}
