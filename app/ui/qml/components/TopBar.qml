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
            id: appTitle
            text: "Proximi"
            color: appTitleMouse.containsMouse && appTitleMouse.canGoHome ? Theme.accentHover : Theme.textPrimary
            font.pixelSize: Theme.fontDisplay
            font.weight: Font.Bold
            font.letterSpacing: 1.2
            Layout.alignment: Qt.AlignVCenter
            Behavior on color { ColorAnimation { duration: 150 } }

            MouseArea {
                id: appTitleMouse
                anchors.fill: parent
                hoverEnabled: true
                property bool canGoHome: typeof similarityController !== "undefined" && similarityController.similarityState === "ready"
                cursorShape: canGoHome ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (canGoHome) {
                        similarityController.resetState()
                    }
                }
            }
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
            id: allPhotosPill
            visible: hasScanned || isScanning
            Layout.preferredHeight: 28
            Layout.preferredWidth: allPhotosRow.width + 20
            radius: 14
            
            property bool isInGroupReview: typeof similarityController !== "undefined"
                                           && similarityController.similarityState === "ready"
                                           
            color: isInGroupReview 
                   ? (allPhotosMouse.containsMouse ? Theme.bgCard : Theme.bgHover) 
                   : Theme.accent
                   
            Behavior on color { ColorAnimation { duration: 150 } }

            Row {
                id: allPhotosRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: allPhotosPill.isInGroupReview ? "‹" : "🖼"
                    color: allPhotosPill.isInGroupReview ? Theme.textSecondary : Theme.textPrimary
                    font.pixelSize: allPhotosPill.isInGroupReview ? 16 : 12
                    font.bold: allPhotosPill.isInGroupReview
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: allPhotosPill.isInGroupReview ? "Home" : "All Photos"
                    color: allPhotosPill.isInGroupReview ? Theme.textSecondary : Theme.textPrimary
                    font.pixelSize: Theme.fontSmall
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    visible: !allPhotosPill.isInGroupReview && typeof scanController !== "undefined" && scanController.scannedCount > 0
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

            MouseArea {
                id: allPhotosMouse
                anchors.fill: parent
                hoverEnabled: allPhotosPill.isInGroupReview
                cursorShape: allPhotosPill.isInGroupReview ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (allPhotosPill.isInGroupReview) {
                        similarityController.resetState()
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

            // ── Custom Dropdown Menu ───────────────────────────────────
            Popup {
                id: actionMenu
                y: menuButton.height + 8
                x: menuButton.width - width
                width: 220
                padding: 0
                modal: false
                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

                enter: Transition {
                    NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 140; easing.type: Easing.OutCubic }
                    NumberAnimation { property: "scale"; from: 0.92; to: 1.0; duration: 140; easing.type: Easing.OutCubic }
                }
                exit: Transition {
                    NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 100; easing.type: Easing.InCubic }
                }

                background: Rectangle {
                    color: "#1A1A26"
                    radius: Theme.radiusL
                    border.color: "#35354A"
                    border.width: 1

                    // Top accent line
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.topMargin: 0
                        height: 2
                        radius: 2
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.4; color: Theme.accent }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                    }

                    // Drop shadow layer
                    layer.enabled: true
                    layer.effect: null
                }

                contentItem: Column {
                    spacing: 0
                    topPadding: 8
                    bottomPadding: 8

                    // ── Export & End Session ────────────────────────────────
                    Rectangle {
                        id: menuItemExportSession
                        visible: hasScanned || isScanning
                        width: 220
                        height: visible ? 44 : 0
                        color: exportSessionMouse.containsMouse ? "#2A2A3E" : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            spacing: 12

                            Rectangle {
                                width: 28; height: 28; radius: 8
                                color: exportSessionMouse.containsMouse ? "#3D2D6A" : "#252535"
                                Behavior on color { ColorAnimation { duration: 120 } }
                                anchors.verticalCenter: parent.verticalCenter
                                Text {
                                    anchors.centerIn: parent
                                    text: "🚀"
                                    font.pixelSize: 13
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1
                                Text {
                                    text: "Export & End Session"
                                    color: "#FFFFFF"
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    font.family: Theme.fontFamily
                                }
                                Text {
                                    text: "Clean, save & return home"
                                    color: "#6B6B82"
                                    font.pixelSize: 10
                                    font.family: Theme.fontFamily
                                }
                            }
                        }

                        MouseArea {
                            id: exportSessionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                actionMenu.close()
                                if (typeof cleanupController !== "undefined") {
                                    cleanupController.commitStagedChanges()
                                }
                                if (typeof scanController !== "undefined") {
                                    var saved = scanController.saveSessionAs()
                                    if (saved) {
                                        scanController.clearTargets()
                                    }
                                }
                            }
                        }
                    }

                    // Divider
                    Rectangle {
                        visible: hasScanned || isScanning
                        width: 220; height: 1
                        color: "#2A2A3A"
                    }

                    // ── Save Session As... ─────────────────────────────
                    Rectangle {
                        id: menuItemSaveSession
                        visible: hasScanned || isScanning
                        width: 220
                        height: visible ? 44 : 0
                        color: saveSessionMouse.containsMouse ? "#2A2A3E" : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            spacing: 12

                            Rectangle {
                                width: 28; height: 28; radius: 8
                                color: saveSessionMouse.containsMouse ? "#3D2D6A" : "#252535"
                                Behavior on color { ColorAnimation { duration: 120 } }
                                anchors.verticalCenter: parent.verticalCenter
                                Text {
                                    anchors.centerIn: parent
                                    text: "💾"
                                    font.pixelSize: 13
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1
                                Text {
                                    text: "Save Session As..."
                                    color: "#FFFFFF"
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    font.family: Theme.fontFamily
                                }
                                Text {
                                    text: "Save folders to a file"
                                    color: "#6B6B82"
                                    font.pixelSize: 10
                                    font.family: Theme.fontFamily
                                }
                            }
                        }

                        MouseArea {
                            id: saveSessionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                actionMenu.close()
                                if (typeof scanController !== "undefined") scanController.saveSessionAs()
                            }
                        }
                    }

                    // Divider
                    Rectangle {
                        visible: hasScanned || isScanning
                        width: 220; height: 1
                        color: "#2A2A3A"
                    }

                    // ── Load Session... ────────────────────────────────
                    Rectangle {
                        id: menuItemLoadSession
                        visible: true
                        width: 220
                        height: 44
                        color: loadSessionMouse.containsMouse ? "#2A2A3E" : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            spacing: 12

                            Rectangle {
                                width: 28; height: 28; radius: 8
                                color: loadSessionMouse.containsMouse ? "#3D2D6A" : "#252535"
                                Behavior on color { ColorAnimation { duration: 120 } }
                                anchors.verticalCenter: parent.verticalCenter
                                Text {
                                    anchors.centerIn: parent
                                    text: "📂"
                                    font.pixelSize: 13
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1
                                Text {
                                    text: "Load Session..."
                                    color: "#FFFFFF"
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    font.family: Theme.fontFamily
                                }
                                Text {
                                    text: "Resume a saved project"
                                    color: "#6B6B82"
                                    font.pixelSize: 10
                                    font.family: Theme.fontFamily
                                }
                            }
                        }

                        MouseArea {
                            id: loadSessionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                actionMenu.close()
                                if (typeof scanController !== "undefined") scanController.loadSession()
                            }
                        }
                    }

                    // Divider
                    Rectangle {
                        width: 220; height: 1
                        color: "#2A2A3A"
                    }

                    // ── Add More Files ─────────────────────────────────
                    Rectangle {
                        id: menuItemAddFiles
                        visible: hasScanned || isScanning
                        width: 220
                        height: visible ? 44 : 0
                        color: addFilesMouse.containsMouse ? "#2A2A3E" : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            spacing: 12

                            Rectangle {
                                width: 28; height: 28; radius: 8
                                color: addFilesMouse.containsMouse ? "#3D2D6A" : "#252535"
                                Behavior on color { ColorAnimation { duration: 120 } }
                                anchors.verticalCenter: parent.verticalCenter
                                Text {
                                    anchors.centerIn: parent
                                    text: "🖼️"
                                    font.pixelSize: 13
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1
                                Text {
                                    text: "Add More Files"
                                    color: "#FFFFFF"
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    font.family: Theme.fontFamily
                                }
                                Text {
                                    text: "Pick individual image files"
                                    color: "#6B6B82"
                                    font.pixelSize: 10
                                    font.family: Theme.fontFamily
                                }
                            }
                        }

                        MouseArea {
                            id: addFilesMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                actionMenu.close()
                                if (typeof scanController !== "undefined") scanController.addFileTargets()
                            }
                        }
                    }

                    // Divider
                    Rectangle {
                        visible: hasScanned || isScanning
                        width: 220; height: 1
                        color: "#2A2A3A"
                    }

                    // ── Add More Folder ────────────────────────────────
                    Rectangle {
                        id: menuItemAddFolder
                        visible: hasScanned || isScanning
                        width: 220
                        height: visible ? 44 : 0
                        color: addFolderMouse.containsMouse ? "#2A2A3E" : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            spacing: 12

                            Rectangle {
                                width: 28; height: 28; radius: 8
                                color: addFolderMouse.containsMouse ? "#3D2D6A" : "#252535"
                                Behavior on color { ColorAnimation { duration: 120 } }
                                anchors.verticalCenter: parent.verticalCenter
                                Text {
                                    anchors.centerIn: parent
                                    text: "📂"
                                    font.pixelSize: 13
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1
                                Text {
                                    text: "Add More Folder"
                                    color: "#FFFFFF"
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    font.family: Theme.fontFamily
                                }
                                Text {
                                    text: "Include another photo folder"
                                    color: "#6B6B82"
                                    font.pixelSize: 10
                                    font.family: Theme.fontFamily
                                }
                            }
                        }

                        MouseArea {
                            id: addFolderMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                actionMenu.close()
                                if (typeof scanController !== "undefined") scanController.addFolderTarget()
                            }
                        }
                    }

                    // Divider
                    Rectangle {
                        visible: hasScanned || isScanning
                        width: 220; height: 1
                        color: "#2A2A3A"
                    }

                    // ── Change Folder ──────────────────────────────────
                    Rectangle {

                        id: menuItemChangeFolder
                        visible: hasScanned && !isScanning
                        width: 220
                        height: visible ? 44 : 0
                        color: changeFolderMouse.containsMouse ? "#2A2A3E" : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            spacing: 12

                            Rectangle {
                                width: 28; height: 28; radius: 8
                                color: changeFolderMouse.containsMouse ? "#3D2D6A" : "#252535"
                                Behavior on color { ColorAnimation { duration: 120 } }
                                anchors.verticalCenter: parent.verticalCenter
                                Text {
                                    anchors.centerIn: parent
                                    text: "📁"
                                    font.pixelSize: 13
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1
                                Text {
                                    text: "Change Folder"
                                    color: "#FFFFFF"
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    font.family: Theme.fontFamily
                                }
                                Text {
                                    text: "Select a new photo folder"
                                    color: "#6B6B82"
                                    font.pixelSize: 10
                                    font.family: Theme.fontFamily
                                }
                            }
                        }

                        MouseArea {
                            id: changeFolderMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                actionMenu.close()
                                if (typeof similarityController !== "undefined") similarityController.resetState()
                                if (typeof scanController !== "undefined") scanController.selectFolder()
                            }
                        }
                    }

                    // Divider after Change Folder
                    Rectangle {
                        visible: hasScanned && !isScanning
                        width: 220; height: 1
                        color: "#2A2A3A"
                    }

                    // ── Rescan ─────────────────────────────────────────
                    Rectangle {
                        id: menuItemRescan
                        visible: hasScanned || isScanning
                        width: 220
                        height: visible ? 44 : 0
                        property bool isScanningProp: isScanning
                        property bool isEnabled: !isScanningProp && (typeof similarityController === "undefined" || similarityController.similarityState !== "processing")
                        color: (rescanMouse.containsMouse && isEnabled) ? "#2A2A3E" : "transparent"
                        opacity: isEnabled ? 1.0 : 0.45
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            spacing: 12

                            Rectangle {
                                width: 28; height: 28; radius: 8
                                color: rescanMouse.containsMouse ? "#3D2D6A" : "#252535"
                                Behavior on color { ColorAnimation { duration: 120 } }
                                anchors.verticalCenter: parent.verticalCenter
                                Text {
                                    anchors.centerIn: parent
                                    text: "🔄"
                                    font.pixelSize: 13
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1
                                Text {
                                    text: menuItemRescan.isScanningProp
                                          ? "Scanning... " + (typeof scanController !== "undefined" ? scanController.scanProgress : 0) + "%"
                                          : "Rescan"
                                    color: "#FFFFFF"
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    font.family: Theme.fontFamily
                                }
                                Text {
                                    text: "Re-index all images"
                                    color: "#6B6B82"
                                    font.pixelSize: 10
                                    font.family: Theme.fontFamily
                                }
                            }
                        }

                        MouseArea {
                            id: rescanMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: menuItemRescan.isEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (!menuItemRescan.isEnabled) return
                                actionMenu.close()
                                if (typeof scanController !== "undefined") {
                                    if (typeof similarityController !== "undefined") similarityController.resetState()
                                    scanController.startScan()
                                }
                            }
                        }
                    }

                    // Divider
                    Rectangle {
                        visible: hasScanned || isScanning
                        width: 220; height: 1
                        color: "#2A2A3A"
                    }

                    // ── Clean Duplicates ───────────────────────────────
                    Rectangle {
                        id: menuItemClean
                        visible: isLoaded
                        width: 220
                        height: visible ? 44 : 0
                        property bool isRemoving: typeof scanController !== "undefined" && scanController.isRemovingDuplicates
                        property int duplicateProgress: typeof scanController !== "undefined" ? scanController.duplicateProgress : 0
                        property bool isEnabled: !isRemoving && (typeof similarityController === "undefined" || similarityController.similarityState !== "processing")
                        color: (cleanMouse.containsMouse && isEnabled) ? "#2A2A3E" : "transparent"
                        opacity: isEnabled ? 1.0 : 0.45
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            spacing: 12

                            Rectangle {
                                width: 28; height: 28; radius: 8
                                color: cleanMouse.containsMouse ? "#3D2D6A" : "#252535"
                                Behavior on color { ColorAnimation { duration: 120 } }
                                anchors.verticalCenter: parent.verticalCenter
                                Text {
                                    anchors.centerIn: parent
                                    text: "🧹"
                                    font.pixelSize: 13
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1
                                Text {
                                    text: menuItemClean.isRemoving
                                          ? "Cleaning... " + menuItemClean.duplicateProgress + "%"
                                          : "Clean Duplicates"
                                    color: "#FFFFFF"
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    font.family: Theme.fontFamily
                                }
                                Text {
                                    text: "Remove exact duplicate files"
                                    color: "#6B6B82"
                                    font.pixelSize: 10
                                    font.family: Theme.fontFamily
                                }
                            }
                        }

                        MouseArea {
                            id: cleanMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: menuItemClean.isEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (!menuItemClean.isEnabled) return
                                actionMenu.close()
                                if (typeof scanController !== "undefined") scanController.removeExactDuplicates()
                            }
                        }
                    }

                    // Divider
                    Rectangle {
                        visible: isLoaded
                        width: 220; height: 1
                        color: "#2A2A3A"
                    }

                    // ── Find Similar ───────────────────────────────────
                    Rectangle {
                        id: menuItemSimilar
                        visible: isLoaded
                        width: 220
                        height: visible ? 44 : 0
                        property bool isEnabled: typeof similarityController !== "undefined" && similarityController.similarityState !== "processing"
                        color: (similarMouse.containsMouse && isEnabled) ? "#2A2A3E" : "transparent"
                        opacity: isEnabled ? 1.0 : 0.45
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            spacing: 12

                            Rectangle {
                                width: 28; height: 28; radius: 8
                                color: similarMouse.containsMouse ? "#3D2D6A" : "#252535"
                                Behavior on color { ColorAnimation { duration: 120 } }
                                anchors.verticalCenter: parent.verticalCenter
                                Text {
                                    anchors.centerIn: parent
                                    text: "✨"
                                    font.pixelSize: 13
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1
                                Text {
                                    text: "Find Similar"
                                    color: "#FFFFFF"
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    font.family: Theme.fontFamily
                                }
                                Text {
                                    text: "Group near-duplicate photos"
                                    color: "#6B6B82"
                                    font.pixelSize: 10
                                    font.family: Theme.fontFamily
                                }
                            }
                        }

                        MouseArea {
                            id: similarMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: menuItemSimilar.isEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (!menuItemSimilar.isEnabled) return
                                actionMenu.close()
                                if (typeof similarityController !== "undefined") similarityController.startSimilarityProcessing()
                            }
                        }
                    }
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
