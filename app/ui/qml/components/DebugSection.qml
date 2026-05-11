import QtQuick
import QtQuick.Layouts
import themes 1.0

ColumnLayout {
    id: sectionRoot

    property string title: ""
    property var metrics: []

    Layout.fillWidth: true
    spacing: 0

    // Section header
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 24
        color: "#141414"

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: sectionRoot.title
            color: Theme.textMuted
            font.pixelSize: 9
            font.weight: Font.Bold
            font.family: "Consolas, monospace"
            font.letterSpacing: 1.5
        }
    }

    // Metric rows
    Repeater {
        model: sectionRoot.metrics

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 22
            color: index % 2 === 0 ? "#0F0F0F" : "#121212"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                Text {
                    text: modelData.label
                    color: Theme.textDisabled
                    font.pixelSize: 10
                    font.family: "Consolas, monospace"
                    Layout.preferredWidth: 90
                }

                Text {
                    text: modelData.value
                    color: Theme.textSecondary
                    font.pixelSize: 10
                    font.family: "Consolas, monospace"
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }

    // Separator
    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Theme.border
    }
}
