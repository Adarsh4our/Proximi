import QtQuick
import themes 1.0

Item {
    id: cardRoot

    property string thumbnailSource: ""
    property string fileName: ""
    property int imageId: -1
    property string selectionState: "unselected"

    Component.onCompleted: {
        if (typeof cleanupController !== "undefined" && cardRoot.imageId !== -1) {
            cardRoot.selectionState = cleanupController.selectionState[String(cardRoot.imageId)] || "unselected"
        }
    }

    Connections {
        target: typeof cleanupController !== "undefined" ? cleanupController : null
        function onSelectionStateChanged() {
            if (cardRoot.imageId !== -1) {
                cardRoot.selectionState = cleanupController.selectionState[String(cardRoot.imageId)] || "unselected"
            }
        }
    }


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

        // Rejected Overlay
        Rectangle {
            anchors.fill: parent
            color: "#EF4444" // Red overlay
            opacity: cardRoot.selectionState === "rejected" ? 0.3 : 0
            
            Behavior on opacity { NumberAnimation { duration: 150 } }
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

        // Dynamic Border (Keeper / Hover)
        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusS
            color: "transparent"
            border.width: cardRoot.selectionState === "keeper" ? 3 : (mouseArea.containsMouse ? 1 : 0)
            border.color: cardRoot.selectionState === "keeper" ? "#22C55E" : Theme.borderLight
            
            Behavior on border.width { NumberAnimation { duration: 100 } }
        }

        // Top-right icon badge (✓ / ✕)
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 4
            width: 24
            height: 24
            radius: 12
            color: cardRoot.selectionState === "keeper" ? "#22C55E" : "#EF4444"
            opacity: cardRoot.selectionState !== "unselected" ? 1 : 0
            
            Text {
                anchors.centerIn: parent
                text: cardRoot.selectionState === "keeper" ? "✓" : "✕"
                color: "white"
                font.bold: true
                font.pixelSize: 14
            }
            
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        // Bottom "KEEPER" label — clearly visible pill badge
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 6
            width: keeperLabel.implicitWidth + 16
            height: 22
            radius: 11
            color: "#22C55E"
            opacity: cardRoot.selectionState === "keeper" ? 1 : 0
            visible: opacity > 0

            Behavior on opacity { NumberAnimation { duration: 150 } }

            Text {
                id: keeperLabel
                anchors.centerIn: parent
                text: "KEEPER"
                color: "white"
                font.bold: true
                font.pixelSize: 10
                font.letterSpacing: 1
            }
        }

        // Mouse area for hover and selection detection
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            
            onClicked: {
                if (typeof cleanupController !== "undefined") {
                    // Only focus/select on click, but for now we toggle unselected/rejected per instructions unless spacebar is used?
                    // Ah, prompt says "Single click: focus/select image only. Explicit actions: K/X/Space".
                    // Actually, if we just want it to focus, we should just emit a signal or set a focusedImage index. 
                    // Let's implement Space for focus selection later, or if we want click to toggle:
                    // Actually, the prompt says: "Do NOT use single-click state cycling... Single click: focus/select image only."
                    // Since we don't have a specific "focused" state for the image card other than hover/keyboard focus, let's let click do standard Focus.
                    cardRoot.forceActiveFocus()
                }
            }
            onDoubleClicked: {
                if (typeof cleanupController !== "undefined") {
                    cleanupController.setKeeper(cardRoot.imageId)
                }
            }
        }
    }
    
    // Focus indicator
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: Theme.accent
        border.width: 2
        radius: Theme.radiusS + 2
        anchors.margins: -2
        visible: cardRoot.activeFocus
    }

    // Keyboard support
    Keys.onPressed: (event) => {
        if (typeof cleanupController === "undefined") return;
        
        if (event.key === Qt.Key_K) {
            cleanupController.setKeeper(cardRoot.imageId)
            event.accepted = true
        } else if (event.key === Qt.Key_X || event.key === Qt.Key_R) {
            cleanupController.toggleSelection(cardRoot.imageId)
            event.accepted = true
        } else if (event.key === Qt.Key_Space) {
            cleanupController.toggleSelection(cardRoot.imageId)
            event.accepted = true
        } else if (event.key === Qt.Key_F || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            // Trigger preview (implemented in parent/group review)
            cardRoot.requestPreview()
            event.accepted = true
        }
    }
    
    signal requestPreview()
}
