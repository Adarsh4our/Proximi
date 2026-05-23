import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import themes 1.0

Item {
    id: loadingRoot

    property int currentCount: 0
    property int totalCount: 0
    property int progressPercent: 0

    // ── Skeleton Grid ─────────────────────────────────────────────────
    GridView {
        id: skeletonGrid
        anchors.fill: parent
        anchors.margins: Theme.gridSpacing
        anchors.bottomMargin: 100  // Reserve space for progress info
        clip: true

        cellWidth: Theme.thumbnailSize + Theme.gridSpacing
        cellHeight: Theme.thumbnailSize + Theme.gridSpacing
        interactive: false

        model: 12

        delegate: Item {
            width: skeletonGrid.cellWidth - Theme.gridSpacing
            height: skeletonGrid.cellHeight - Theme.gridSpacing

            Rectangle {
                id: skeletonCard
                anchors.fill: parent
                anchors.margins: 2
                radius: Theme.radiusS
                color: Theme.bgCard
                clip: true

                // Shimmer sweep
                Rectangle {
                    id: shimmer
                    width: parent.width * 0.4
                    height: parent.height
                    radius: parent.radius
                    opacity: 0.15

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.5; color: Theme.bgHover }
                        GradientStop { position: 1.0; color: "transparent" }
                    }

                    SequentialAnimation on x {
                        loops: Animation.Infinite
                        NumberAnimation {
                            from: -shimmer.width
                            to: skeletonCard.width
                            duration: 1400
                            easing.type: Easing.InOutQuad
                        }
                        PauseAnimation { duration: 200 + index * 60 }
                    }
                }

                // Faint icon placeholder in center
                Text {
                    anchors.centerIn: parent
                    text: "🖼"
                    font.pixelSize: 24
                    opacity: 0.08
                }
            }

            // Staggered entrance
            opacity: 0
            Component.onCompleted: skelEntranceAnim.start()
            SequentialAnimation {
                id: skelEntranceAnim
                PauseAnimation { duration: index * 50 }
                NumberAnimation { target: parent; property: "opacity"; from: 0; to: 1; duration: 300; easing.type: Easing.OutCubic }
            }
        }
    }

    // ── Bottom Progress Section ────────────────────────────────────────
    ColumnLayout {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.spaceL
        spacing: Theme.spaceS

        // Status text
        Text {
            text: loadingRoot.totalCount > 0
                  ? "Scanning... " + loadingRoot.currentCount + " of " + loadingRoot.totalCount + " images"
                  : "Discovering files..."
            color: Theme.textSecondary
            font.pixelSize: Theme.fontBody
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }

        // Progress bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 4
            radius: 2
            color: Theme.bgHover

            Rectangle {
                width: parent.width * (loadingRoot.progressPercent / 100)
                height: parent.height
                radius: 2
                color: Theme.accent

                Behavior on width {
                    NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic }
                }

                // Glowing leading edge
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24
                    height: parent.height + 4
                    radius: 2
                    visible: loadingRoot.progressPercent > 0 && loadingRoot.progressPercent < 100
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 1.0; color: Theme.glowAccent }
                    }
                }
            }
        }

        // Percentage
        Text {
            text: loadingRoot.progressPercent + "%"
            color: Theme.textMuted
            font.pixelSize: Theme.fontSmall
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }
    }
}
