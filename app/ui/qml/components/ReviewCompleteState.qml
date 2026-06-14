import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import themes 1.0

Rectangle {
    id: root
    color: Theme.bgPanel
    
    // Properties to read from controllers
    property int totalGroups: typeof similarityController !== "undefined" ? similarityController.groupCount : 0
    property int totalDeleted: typeof cleanupController !== "undefined" ? cleanupController.totalDeleted : 0
    property bool canUndo: typeof cleanupController !== "undefined" ? cleanupController.canUndo : false

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Theme.spaceL

        Text {
            text: "🎉 Review Complete!"
            color: Theme.textPrimary
            font.pixelSize: 28
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: "You have reviewed all " + root.totalGroups + " similarity groups."
            color: Theme.textSecondary
            font.pixelSize: Theme.fontBody
            Layout.alignment: Qt.AlignHCenter
        }

        // Stats Card
        Rectangle {
            Layout.preferredWidth: 320
            Layout.preferredHeight: 100
            radius: Theme.radiusM
            color: Theme.bgCard
            border.color: Theme.borderLight
            border.width: 1
            Layout.alignment: Qt.AlignHCenter
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: Theme.spaceM
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text { text: "Cleaned Images"; color: Theme.textSecondary; font.pixelSize: Theme.fontSmall; Layout.alignment: Qt.AlignHCenter }
                    Text { text: root.totalDeleted; color: Theme.accent; font.pixelSize: 24; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.spaceM
            Layout.topMargin: Theme.spaceL

            Button {
                text: "Undo Last Action"
                visible: root.canUndo
                onClicked: {
                    if (typeof cleanupController !== "undefined") {
                        cleanupController.undoLastCleanup()
                    }
                }
                
                contentItem: Text {
                    text: parent.text
                    color: Theme.textPrimary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: Theme.radiusS
                    color: parent.hovered ? Theme.bgHover : Theme.bgElevated
                    border.color: Theme.borderLight
                }
            }

            Button {
                text: "Review Again"
                onClicked: {
                    // Quick way to restart review loop without rescanning
                    if (typeof similarityController !== "undefined") {
                        similarityController.previousGroup() // This resets reviewComplete inside the controller
                    }
                }
                
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: Theme.radiusS
                    color: parent.hovered ? Theme.accentHover : Theme.accent
                }
            }
        }
    }
}
