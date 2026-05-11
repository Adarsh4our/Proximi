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

    // ── Image data model ─────────────────────────────────────────────
    ListModel {
        id: imageListModel
    }

    // ── Connect to ScanController signals ────────────────────────────
    Connections {
        target: typeof scanController !== "undefined" ? scanController : null

        function onImageReady(originalPath, thumbnailPath, fileName) {
            imageListModel.append({
                "originalPath": originalPath,
                "thumbnailPath": thumbnailPath,
                "fileName": fileName
            })
        }

        function onScanFinished(totalProcessed) {
            console.log("Scan finished: " + totalProcessed + " images")
        }
    }

    // ── Load stored images on startup ────────────────────────────────
    Component.onCompleted: {
        if (typeof scanController !== "undefined") {
            var storedImages = scanController.getStoredImages()
            if (storedImages && storedImages.length > 0) {
                for (var i = 0; i < storedImages.length; i++) {
                    imageListModel.append(storedImages[i])
                }
            }
        }
    }

    // ── Keyboard shortcut: Ctrl+Shift+D → toggle debug panel ────────
    Shortcut {
        sequence: "Ctrl+Shift+D"
        onActivated: {
            if (typeof debugController !== "undefined")
                debugController.toggle()
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

            Sidebar {
                Layout.preferredWidth: 200
                Layout.fillHeight: true
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: Theme.border
            }

            // Content + Debug panel overlay container
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ContentArea {
                    anchors.fill: parent
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
}
