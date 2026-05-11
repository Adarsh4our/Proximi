import QtQuick
import themes 1.0

Item {
    id: cardRoot

    property string thumbnailSource: ""
    property string fileName: ""

    Rectangle {
        id: cardBg
        anchors.fill: parent
        anchors.margins: 2
        radius: Theme.radiusS
        color: Theme.bgCard
        clip: true

        // Thumbnail image (lazy loaded, async)
        Image {
            id: thumbImage
            anchors.fill: parent
            source: cardRoot.thumbnailSource
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
            mipmap: true

            // Loading placeholder
            Rectangle {
                anchors.fill: parent
                color: Theme.bgHover
                visible: thumbImage.status !== Image.Ready

                Text {
                    anchors.centerIn: parent
                    text: "⏳"
                    font.pixelSize: 16
                    opacity: 0.4
                }
            }
        }

        // Hover overlay — subtle filename label at bottom
        Rectangle {
            id: hoverOverlay
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 28
            color: "#AA000000"
            opacity: mouseArea.containsMouse ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation { duration: 120 }
            }

            Text {
                anchors.fill: parent
                anchors.leftMargin: Theme.spaceXS
                anchors.rightMargin: Theme.spaceXS
                text: cardRoot.fileName
                color: Theme.textPrimary
                font.pixelSize: Theme.fontCaption
                elide: Text.ElideMiddle
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }
        }

        // Subtle hover border
        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusS
            color: "transparent"
            border.width: mouseArea.containsMouse ? 1 : 0
            border.color: Theme.borderLight
        }

        // Mouse area for hover detection
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
        }
    }
}
