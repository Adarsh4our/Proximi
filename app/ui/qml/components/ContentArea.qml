import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import themes 1.0
import "."

Item {
    id: contentRoot

    // External properties bound from Main.qml
    property string scanState: "empty"
    property var imageModel: null
    property int scanProgress: 0
    property int scannedCount: 0
    property int totalImages: 0

    // Empty State
    EmptyState {
        anchors.fill: parent
        visible: contentRoot.scanState === "empty" && (!contentRoot.imageModel || contentRoot.imageModel.count === 0)
    }

    // Image Grid (visible during scanning and after loaded)
    GridView {
        id: imageGrid
        anchors.fill: parent
        anchors.margins: Theme.gridSpacing
        clip: true
        visible: contentRoot.imageModel && contentRoot.imageModel.count > 0

        cellWidth: Theme.thumbnailSize + Theme.gridSpacing
        cellHeight: Theme.thumbnailSize + Theme.gridSpacing
        model: contentRoot.imageModel
        cacheBuffer: 600  // Pre-render items slightly outside viewport

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: 6
                radius: 3
                color: Theme.textDisabled
                opacity: 0.5
            }
        }

        delegate: ImageCard {
            width: imageGrid.cellWidth - Theme.gridSpacing
            height: imageGrid.cellHeight - Theme.gridSpacing
            thumbnailSource: model.thumbnailPath || ""
            fileName: model.fileName || ""
        }

        // Smooth scrolling
        flickDeceleration: 3000
        maximumFlickVelocity: 4000

        // Empty fill transition
        add: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
        }
    }

    // Loading overlay (shown during scan, overlaid on top of growing grid)
    LoadingView {
        anchors.fill: parent
        visible: contentRoot.scanState === "scanning" && (!contentRoot.imageModel || contentRoot.imageModel.count === 0)
        currentCount: contentRoot.scannedCount
        totalCount: contentRoot.totalImages
        progressPercent: contentRoot.scanProgress
    }

    // Compact progress bar at top when scanning with grid visible
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 3
        color: "transparent"
        visible: contentRoot.scanState === "scanning" && contentRoot.imageModel && contentRoot.imageModel.count > 0

        Rectangle {
            width: parent.width * (contentRoot.scanProgress / 100)
            height: parent.height
            color: Theme.accent

            Behavior on width {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
        }
    }
}
