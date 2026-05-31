import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import themes 1.0

Rectangle {
    color: Theme.bgGlass

    // Bottom glow line
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.accentGlow
    }

    // Derived state helpers
    property bool hasFolder: typeof scanController !== "undefined" && scanController.currentFolder !== ""
    property bool isScanning: typeof scanController !== "undefined" && scanController.scanState === "scanning"
    property bool isLoaded: typeof scanController !== "undefined" && scanController.scanState === "loaded"
    property bool hasScanned: typeof scanController !== "undefined" && scanController.hasScannedCurrentFolder

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.spaceM

        // App title
        Text {
            text: "Proximi"
            color: Theme.textPrimary
            font.pixelSize: Theme.fontDisplay
            font.weight: Font.Bold
            font.letterSpacing: 1.2
            Layout.alignment: Qt.AlignVCenter
        }

        // Separator (always visible)
        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: 24
            Layout.leftMargin: Theme.spaceM
            Layout.rightMargin: Theme.spaceS
            color: Theme.border
        }

        // ── "All Photos" pill — shown after scan ─────────────────────
        Rectangle {
            visible: (hasScanned || isScanning) && !isInGroupReview
            Layout.preferredHeight: 28
            Layout.preferredWidth: allPhotosRow.width + 20
            radius: 14
            color: Theme.accent

            property bool isInGroupReview: typeof similarityController !== "undefined"
                                           && similarityController.similarityState === "ready"

            Row {
                id: allPhotosRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: "🖼"
                    font.pixelSize: 12
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "All Photos"
                    color: Theme.textPrimary
                    font.pixelSize: Theme.fontSmall
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    visible: typeof scanController !== "undefined" && scanController.scannedCount > 0
                    width: pillCountText.implicitWidth + 10
                    height: 18
                    radius: 9
                    color: Theme.accentHover
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        id: pillCountText
                        anchors.centerIn: parent
                        text: typeof scanController !== "undefined" ? scanController.scannedCount : "0"
                        color: Theme.textPrimary
                        font.pixelSize: 10
                        font.bold: true
                    }
                }
            }
        }

        // ── Folder path chip — styled breadcrumb ─────────────────────
        Rectangle {
            id: folderChip
            visible: hasScanned || isScanning
            Layout.preferredHeight: 28
            Layout.preferredWidth: folderChipRow.width + 16
            radius: 14
            color: Theme.bgHover

            property string fullPath: typeof scanController !== "undefined" ? scanController.currentFolder : ""

            Row {
                id: folderChipRow
                anchors.centerIn: parent
                spacing: 5

                Text {
                    text: "📂"
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: {
                        if (!folderChip.fullPath || folderChip.fullPath === "") return ""
                        var parts = folderChip.fullPath.replace(/\\/g, "/").split("/")
                        if (parts.length > 2) {
                            // Show last 2 segments as breadcrumb
                            return parts[parts.length - 2] + " › " + parts[parts.length - 1]
                        }
                        return parts[parts.length - 1]
                    }
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontSmall
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: folderChipMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
            }
        }

        // Spacer
        Item {
            Layout.fillWidth: true
        }

        // ── Action buttons ───────────────────────────────────────────

        // Hamburger Menu Button
        Rectangle {
            id: menuButton
            visible: hasScanned || isScanning || isLoaded
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            radius: Theme.radiusL
            color: menuButtonMouse.containsMouse ? Theme.bgHover : "transparent"
            border.color: menuButtonMouse.containsMouse ? Theme.accentGlow : Theme.border
            border.width: 1
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "≡"
                color: Theme.textPrimary
                font.pixelSize: 22
                // Minor vertical offset tweak to perfectly center the hamburger icon
                anchors.verticalCenterOffset: -2
            }

            MouseArea {
                id: menuButtonMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: actionMenu.open()
            }

            Menu {
                id: actionMenu
                y: menuButton.height + 4
                x: menuButton.width - width

                MenuItem {
                    text: "Change Folder"
                    visible: hasScanned && !isScanning
                    onTriggered: {
                        if (typeof similarityController !== "undefined") {
                            similarityController.resetState()
                        }
                        if (typeof scanController !== "undefined") {
                            scanController.selectFolder()
                        }
                    }
                }

                MenuItem {
                    property bool isScanningProp: isScanning
                    text: isScanningProp ? "Scanning... " + (typeof scanController !== "undefined" ? scanController.scanProgress : 0) + "%" : "Rescan"
                    visible: hasScanned || isScanning
                    enabled: !isScanningProp && (typeof similarityController === "undefined" || similarityController.similarityState !== "processing")
                    onTriggered: {
                        if (typeof scanController !== "undefined") {
                            if (typeof similarityController !== "undefined") {
                                similarityController.resetState()
                            }
                            scanController.startScan()
                        }
                    }
                }

                MenuItem {
                    property bool isRemoving: typeof scanController !== "undefined" && scanController.isRemovingDuplicates
                    property int duplicateProgress: typeof scanController !== "undefined" ? scanController.duplicateProgress : 0
                    text: isRemoving ? "Cleaning... " + duplicateProgress + "%" : "Clean Duplicates"
                    visible: isLoaded
                    enabled: !isRemoving && (typeof similarityController === "undefined" || similarityController.similarityState !== "processing")
                    onTriggered: {
                        if (typeof scanController !== "undefined") {
                            scanController.removeExactDuplicates()
                        }
                    }
                }

                MenuItem {
                    text: "Find Similar"
                    visible: isLoaded
                    enabled: typeof similarityController !== "undefined" && similarityController.similarityState !== "processing"
                    onTriggered: {
                        if (typeof similarityController !== "undefined") {
                            similarityController.startSimilarityProcessing()
                        }
                    }
                }
                
                background: Rectangle {
                    implicitWidth: 200
                    color: Theme.bgPanel
                    border.color: Theme.border
                    radius: Theme.radiusM
                }
            }
        }

        // ── Staged Commit Controls ───────────────────────────────────
        RowLayout {
            visible: typeof cleanupController !== "undefined" && cleanupController.stagedCount > 0
            spacing: Theme.spaceS
            Layout.leftMargin: Theme.spaceM
            
            Rectangle {
                Layout.preferredWidth: stagedLabel.implicitWidth + 24
                Layout.preferredHeight: 32
                radius: 16
                color: "#F59E0B" // Amber background

                Row {
                    id: stagedLabel
                    anchors.centerIn: parent
                    spacing: 6
                    Text { text: "⏳"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        text: (typeof cleanupController !== "undefined" ? cleanupController.stagedCount : 0) + " Staged"
                        color: "white"
                        font.bold: true
                        font.pixelSize: Theme.fontSmall
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Button {
                id: commitBtn
                text: "Apply Changes"
                onClicked: cleanupController.commitStagedChanges()
                background: Rectangle {
                    color: commitBtn.hovered ? "#059669" : "#10B981" // Green
                    radius: Theme.radiusL
                }
                contentItem: Text {
                    text: commitBtn.text
                    color: "white"
                    font.bold: true
                    font.pixelSize: Theme.fontSmall
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 12
                    rightPadding: 12
                }
            }

            Button {
                id: discardBtn
                text: "Discard"
                onClicked: cleanupController.clearStagedChanges()
                background: Rectangle {
                    color: discardBtn.hovered ? Theme.bgHover : "transparent"
                    border.color: discardBtn.hovered ? Theme.accentGlow : Theme.border
                    border.width: 1
                    radius: Theme.radiusL
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                }
                contentItem: Text {
                    text: discardBtn.text
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontSmall
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 12
                    rightPadding: 12
                }
            }

            // Divider
            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 24
                color: Theme.border
                Layout.leftMargin: Theme.spaceS
                Layout.rightMargin: Theme.spaceS
            }
        }

        Item {
            Layout.preferredWidth: Theme.spaceS
        }

        // Settings icon button
        Rectangle {
            width: 32; height: 32; radius: 16
            color: settingsIconMouse.containsMouse ? Theme.bgHover : "transparent"
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: "⚙"
                color: Theme.textSecondary
                font.pixelSize: Theme.fontTitle
            }

            MouseArea {
                id: settingsIconMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (typeof settingsController !== "undefined")
                        settingsController.toggleSettingsPanel()
                }
            }
        }
    }
}
