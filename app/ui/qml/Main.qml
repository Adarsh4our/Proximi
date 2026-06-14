import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import themes 1.0
import "components"

ApplicationWindow {
    id: root
    width: 1280
    height: 800
    minimumWidth: 800
    minimumHeight: 600
    visible: true
    title: qsTr("Proximi")

    color: Theme.bgApp
    font.family: Theme.fontFamily

    // Used to bypass the save-on-close guard when the user explicitly chose to exit
    property bool forceClose: false

    // ── Intercept window close to ask about saving session ──────────
    onClosing: function(close) {
        if (forceClose) {
            close.accepted = true
            return
        }
        if (typeof scanController !== "undefined" && scanController.scannedCount > 0) {
            close.accepted = false
            closeConfirmDialog.open()
        } else {
            close.accepted = true
        }
    }
    // ── Image data model ─────────────────────────────────────────────
    ListModel {
        id: imageListModel
    }

    // ── Connect to ScanController signals ────────────────────────────
    Connections {
        target: typeof scanController !== "undefined" ? scanController : null

        function onScanStarted() {
            imageListModel.clear()
        }

        function onImageReady(imageId, originalPath, thumbnailPath, fileName) {
            imageListModel.append({
                "imageId": imageId,
                "originalPath": originalPath,
                "thumbnailPath": thumbnailPath,
                "fileName": fileName
            })
        }

        function onScanFinished(totalProcessed) {
            console.log("Scan finished: " + totalProcessed + " images")
        }

        function onDuplicateRemovalFinished(removedPaths) {
            console.log("Duplicate removal finished, removed " + removedPaths.length + " exact duplicates.")
            if (removedPaths.length > 0) {
                // Reload the model to reflect the removed images
                imageListModel.clear()
                var images = scanController.getStoredImages()
                for (var i = 0; i < images.length; i++) {
                    imageListModel.append(images[i])
                }
            }
        }
    }

    // ── Startup initialization ───────────────────────────────────────
    Component.onCompleted: {
        // App starts fresh by default
    }

    // ── Keyboard shortcut: Ctrl+Shift+D → toggle debug panel ────────
    Shortcut {
        sequence: "Ctrl+Shift+D"
        onActivated: {
            if (typeof debugController !== "undefined")
                debugController.toggle()
        }
    }

    // ── Global Escape → close fullscreen preview ─────────────────────
    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (globalPreviewModal.visible)
                globalPreviewModal.closePreview()
        }
    }

    // ── Layout ───────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TopBar {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.border
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Derived state for sidebar visibility
            property bool inGroupReview: typeof similarityController !== "undefined"
                                         && similarityController.similarityState === "ready"

            Sidebar {
                visible: parent.inGroupReview || sidebarWidthAnim.running
                Layout.preferredWidth: parent.inGroupReview ? 220 : 0
                Layout.fillHeight: true
                clip: true

                Behavior on Layout.preferredWidth {
                    NumberAnimation {
                        id: sidebarWidthAnim
                        duration: Theme.animPage
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Rectangle {
                visible: parent.inGroupReview || sidebarWidthAnim.running
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: Theme.border
                opacity: parent.inGroupReview ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: Theme.animPage } }
            }

            // Content + Debug panel overlay container
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ContentArea {
                    anchors.fill: parent
                    visible: true
                    scanState: typeof scanController !== "undefined" ? scanController.scanState : "empty"
                    imageModel: imageListModel
                    scanProgress: typeof scanController !== "undefined" ? scanController.scanProgress : 0
                    scannedCount: typeof scanController !== "undefined" ? scanController.scannedCount : 0
                    totalImages: typeof scanController !== "undefined" ? scanController.totalImages : 0
                }

                // Debug panel overlays on right edge of content area
                DebugPanel {
                    panelVisible: typeof debugController !== "undefined" ? debugController.visible : false
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.border
        }

        Footer {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
        }
    }

    // Settings panel overlay — renders on top of everything
    SettingsPanel {
        anchors.fill: parent
    }

    // ── Global fullscreen preview modal — accessible from all views ──
    ImagePreviewModal {
        id: globalPreviewModal
        anchors.fill: parent
        z: 9999
    }

    // ── Onboarding overlay — first launch only ──────────────────────
    OnboardingOverlay {
        id: onboardingOverlay
        anchors.fill: parent
        z: 10000

        // Show when the user hasn't completed onboarding yet
        visible: typeof settingsController !== "undefined"
                 && !settingsController.onboardingCompleted

        // Opacity-based entrance/exit so we can fade out on completion
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: Theme.animPage; easing.type: Easing.OutCubic } }

        onCompleted: {
            if (typeof settingsController !== "undefined")
                settingsController.completeOnboarding()
        }
    }
    // ── Close Confirmation Dialog ────────────────────────────────────
    Popup {
        id: closeConfirmDialog
        anchors.centerIn: parent
        width: 480
        height: 240
        modal: true
        focus: true
        closePolicy: Popup.NoAutoClose

        background: Rectangle {
            color: Theme.bgCard
            radius: Theme.radiusL
            border.color: Theme.border
            border.width: 1

            layer.enabled: true
            layer.effect: null
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spaceL
            spacing: Theme.spaceM

            Text {
                text: "Save Session?"
                color: Theme.textPrimary
                font.pixelSize: Theme.fontHeader
                font.bold: true
                Layout.fillWidth: true
            }

            Text {
                text: "Do you want to save the current folders to a file so you can load them later?"
                color: Theme.textSecondary
                font.pixelSize: Theme.fontBody
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Item { Layout.fillHeight: true } // spacer

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spaceM

                // Cancel Button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: Theme.radiusS
                    color: cancelMouse.containsMouse ? Theme.bgHover : "transparent"
                    border.color: Theme.border
                    border.width: 1
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontBody
                        font.bold: true
                    }
                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: closeConfirmDialog.close()
                    }
                }

                // Discard Button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: Theme.radiusS
                    color: discardMouse.containsMouse ? "#3A1B1B" : "transparent"
                    border.color: "#5A2B2B"
                    border.width: 1
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Discard & Exit"
                        color: "#FF5555"
                        font.pixelSize: Theme.fontBody
                        font.bold: true
                    }
                    MouseArea {
                        id: discardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            closeConfirmDialog.close()
                            root.forceClose = true
                            Qt.quit()
                        }
                    }
                }

                // Save Button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: Theme.radiusS
                    color: saveMouse.containsMouse ? Theme.accentHover : Theme.accent
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Save & Exit"
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontBody
                        font.bold: true
                    }
                    MouseArea {
                        id: saveMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof scanController !== "undefined") {
                                var saved = scanController.saveSessionAs()
                                if (saved) {
                                    closeConfirmDialog.close()
                                    root.forceClose = true
                                    Qt.quit()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
