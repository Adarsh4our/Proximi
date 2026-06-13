import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import themes 1.0

FocusScope {
    id: root
    visible: false
    opacity: 0

    // ── Public API ────────────────────────────────────────────────────
    property string imageSource: ""
    property string imageFileName: ""

    // Optional list-based navigation
    // Pass an array of { source, fileName } objects and a start index
    property var imageList: []
    property int currentIndex: 0

    // ── Open / Close ──────────────────────────────────────────────────
    function openPreview(src, fileName) {
        imageSource = src || ""
        imageFileName = fileName || extractFileName(src)
        imageList = []      // Single-image mode
        currentIndex = 0
        if (typeof flickable !== "undefined") flickable.zoomScale = 1.0
        _show()
    }

    function openPreviewList(list, startIndex) {
        imageList = list || []
        currentIndex = Math.max(0, Math.min(startIndex || 0, list.length - 1))
        if (list.length > 0) {
            imageSource = list[currentIndex].source || ""
            imageFileName = list[currentIndex].fileName || extractFileName(imageSource)
        }
        if (typeof flickable !== "undefined") flickable.zoomScale = 1.0
        _show()
    }

    function closePreview() {
        if (typeof flickable !== "undefined") flickable.zoomScale = 1.0
        root.opacity = 0
    }

    function _show() {
        root.visible = true
        root.opacity = 1
        if (typeof flickable !== "undefined") flickable.zoomScale = 1.0
        focusTimer.restart()
    }

    // Small delay so the modal is fully visible before stealing focus
    Timer {
        id: focusTimer
        interval: 50
        repeat: false
        onTriggered: focusItem.forceActiveFocus()
    }

    function extractFileName(path) {
        if (!path) return ""
        var parts = path.replace(/\\/g, "/").split("/")
        return parts[parts.length - 1]
    }

    function _navigateTo(index) {
        if (imageList.length === 0) return
        currentIndex = (index + imageList.length) % imageList.length
        
        if (typeof flickable !== "undefined") flickable.zoomScale = 1.0
        
        // Manual crossfade logic
        previewImage.opacity = 0.5
        imageSource = imageList[currentIndex].source || ""
        imageFileName = imageList[currentIndex].fileName || extractFileName(imageSource)
        previewImage.opacity = 1.0
    }

    // ── Animation ─────────────────────────────────────────────────────
    Behavior on opacity {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
            onRunningChanged: {
                if (!running && root.opacity === 0) {
                    root.visible = false
                }
            }
        }
    }

    // ── Dim Background ────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#EE000000"   // 93% black

        MouseArea {
            anchors.fill: parent
            onClicked: root.closePreview()
        }
    }

    // ── Image Container with scale animation ──────────────────────────
    Flickable {
        id: flickable
        anchors.fill: parent
        anchors.topMargin: 56     // space for top bar
        anchors.bottomMargin: 64  // space for info bar
        anchors.leftMargin: imageList.length > 1 ? 64 : 16
        anchors.rightMargin: imageList.length > 1 ? 64 : 16

        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: zoomScale > 1.0

        property real zoomScale: 1.0
        property real minZoom: 1.0
        property real maxZoom: 5.0

        contentWidth: Math.max(width, width * zoomScale)
        contentHeight: Math.max(height, height * zoomScale)

        onZoomScaleChanged: {
            if (zoomScale === 1.0) {
                contentX = 0
                contentY = 0
            }
        }

        Item {
            id: contentWrapper
            width: flickable.contentWidth
            height: flickable.contentHeight

            Image {
                id: previewImage
                anchors.centerIn: parent
                width: flickable.width
                height: flickable.height
                source: root.imageSource
                fillMode: Image.PreserveAspectFit
                autoTransform: true
                asynchronous: true
                smooth: true
                mipmap: true
                scale: flickable.zoomScale

                Behavior on scale {
                    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                }

                Behavior on opacity {
                    NumberAnimation { duration: 120 }
                }
            }

            // Loading spinner
            Item {
                anchors.centerIn: parent
                visible: previewImage.status === Image.Loading
                width: 56
                height: 56

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "#33FFFFFF"
                }

                Text {
                    anchors.centerIn: parent
                    text: "⏳"
                    font.pixelSize: 24
                }

                RotationAnimation on rotation {
                    loops: Animation.Infinite
                    from: 0; to: 360
                    duration: 1200
                }
            }
        }

        // MouseArea for scroll-to-zoom and dragging (panning)
        // MouseArea for scroll-to-zoom and dragging (panning)
        MouseArea {
            id: zoomMouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            
            onClicked: (mouse) => {
                focusItem.forceActiveFocus() // Ensure keyboard capture works
                
                // Map mouse coordinates to the previewImage
                var mapped = zoomMouseArea.mapToItem(previewImage, mouse.x, mouse.y)
                
                // Calculate actual visible image boundaries (PreserveAspectFit centers it)
                var paintedW = previewImage.paintedWidth
                var paintedH = previewImage.paintedHeight
                var imgX = (previewImage.width - paintedW) / 2
                var imgY = (previewImage.height - paintedH) / 2
                
                if (mapped.x < imgX || mapped.x > imgX + paintedW ||
                    mapped.y < imgY || mapped.y > imgY + paintedH) {
                    root.closePreview()
                }
            }

            // Double click to zoom in or out
            onDoubleClicked: {
                if (flickable.zoomScale > 1.0) {
                    flickable.zoomScale = 1.0
                } else {
                    flickable.zoomScale = 2.5
                }
            }

            onWheel: (wheel) => {
                focusItem.forceActiveFocus() // Keep focus for arrow keys
                
                var zoomStep = 1.15
                var oldZoom = flickable.zoomScale
                var newZoom = oldZoom
                if (wheel.angleDelta.y > 0) {
                    newZoom = Math.min(oldZoom * zoomStep, flickable.maxZoom)
                } else {
                    newZoom = Math.max(oldZoom / zoomStep, flickable.minZoom)
                }

                if (newZoom !== oldZoom) {
                    var mouseX = wheel.x
                    var mouseY = wheel.y

                    // Point under mouse in content coordinates
                    var contentXBefore = flickable.contentX + mouseX
                    var contentYBefore = flickable.contentY + mouseY

                    // Relative position (0.0 to 1.0) of that point
                    var ratioX = contentXBefore / flickable.contentWidth
                    var ratioY = contentYBefore / flickable.contentHeight

                    // Apply zoom scale
                    flickable.zoomScale = newZoom
                    
                    // Pre-calculate new dimensions
                    var newContentWidth = Math.max(flickable.width, flickable.width * newZoom)
                    var newContentHeight = Math.max(flickable.height, flickable.height * newZoom)

                    // Re-align that relative position to the mouse cursor
                    var newContentX = (ratioX * newContentWidth) - mouseX
                    var newContentY = (ratioY * newContentHeight) - mouseY

                    flickable.contentX = Math.max(0, Math.min(newContentX, newContentWidth - flickable.width))
                    flickable.contentY = Math.max(0, Math.min(newContentY, newContentHeight - flickable.height))
                }
            }
        }
    }

    // ── Prev Button ───────────────────────────────────────────────────
    Item {
        id: prevBtn
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 56
        height: 56
        visible: imageList.length > 1
        opacity: prevMouse.containsMouse ? 1.0 : 0.6

        Behavior on opacity { NumberAnimation { duration: 120 } }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: prevMouse.containsMouse ? "#55FFFFFF" : "#33FFFFFF"
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        Text {
            anchors.centerIn: parent
            text: "‹"
            color: "white"
            font.pixelSize: 28
            font.bold: true
        }

        MouseArea {
            id: prevMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root._navigateTo(root.currentIndex - 1)
        }
    }

    // ── Next Button ───────────────────────────────────────────────────
    Item {
        id: nextBtn
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 56
        height: 56
        visible: imageList.length > 1
        opacity: nextMouse.containsMouse ? 1.0 : 0.6

        Behavior on opacity { NumberAnimation { duration: 120 } }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: nextMouse.containsMouse ? "#55FFFFFF" : "#33FFFFFF"
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        Text {
            anchors.centerIn: parent
            text: "›"
            color: "white"
            font.pixelSize: 28
            font.bold: true
        }

        MouseArea {
            id: nextMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root._navigateTo(root.currentIndex + 1)
        }
    }

    // ── Top Bar: Close button ─────────────────────────────────────────
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 56
        color: "transparent"

        // Close button
        Item {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 16
            width: 40
            height: 40

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: closeMouse.containsMouse ? "#44FFFFFF" : "#22FFFFFF"
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            Text {
                anchors.centerIn: parent
                text: "✕"
                color: "white"
                font.pixelSize: 18
                font.bold: true
            }

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.closePreview()
            }
        }

        // Keyboard hint
        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 20
            text: imageList.length > 1
                  ? "ESC or F to close  ·  ← → to navigate"
                  : "ESC or F to close"
            color: "#88FFFFFF"
            font.pixelSize: 12
        }
    }

    // ── Bottom Info Bar ───────────────────────────────────────────────
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 64
        color: "#CC000000"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 12

            // Filename
            Text {
                text: root.imageFileName
                color: "white"
                font.pixelSize: 14
                elide: Text.ElideMiddle
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }

            // Image dimensions when loaded
            Text {
                text: (previewImage.sourceSize.width > 0 && previewImage.sourceSize.height > 0)
                      ? previewImage.sourceSize.width + " × " + previewImage.sourceSize.height
                      : ""
                color: "#88FFFFFF"
                font.pixelSize: 13
                Layout.alignment: Qt.AlignVCenter
            }

            // Counter when in list mode
            Text {
                visible: imageList.length > 1
                text: (root.currentIndex + 1) + " / " + imageList.length
                color: "#88FFFFFF"
                font.pixelSize: 13
                font.bold: true
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    // ── Keyboard Capture ──────────────────────────────────────────────
    // Fills the entire modal so it always has a valid geometry for focus
    Item {
        id: focusItem
        anchors.fill: parent
        focus: true
        Keys.onPressed: (event) => {
            switch (event.key) {
                case Qt.Key_Escape:
                case Qt.Key_F:
                    root.closePreview()
                    event.accepted = true
                    break
                case Qt.Key_Left:
                    if (flickable.zoomScale > 1.0) {
                        flickable.contentX = Math.max(0, flickable.contentX - 60)
                    } else {
                        root._navigateTo(root.currentIndex - 1)
                    }
                    event.accepted = true
                    break
                case Qt.Key_Right:
                    if (flickable.zoomScale > 1.0) {
                        flickable.contentX = Math.min(flickable.contentWidth - flickable.width, flickable.contentX + 60)
                    } else {
                        root._navigateTo(root.currentIndex + 1)
                    }
                    event.accepted = true
                    break
                case Qt.Key_Up:
                    if (flickable.zoomScale > 1.0) {
                        flickable.contentY = Math.max(0, flickable.contentY - 60)
                    }
                    event.accepted = true
                    break
                case Qt.Key_Down:
                    if (flickable.zoomScale > 1.0) {
                        flickable.contentY = Math.min(flickable.contentHeight - flickable.height, flickable.contentY + 60)
                    }
                    event.accepted = true
                    break
            }
        }
    }
}
