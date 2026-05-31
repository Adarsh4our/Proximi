import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import themes 1.0

Item {
    id: emptyRoot

    // Bound from ContentArea / ScanController
    property var scanTargets: typeof scanController !== "undefined" ? scanController.scanTargets : []
    property bool folderSelected: scanTargets && scanTargets.length > 0

    // Floating particles
    Repeater {
        model: 3
        Rectangle {
            width: 4 + index * 3
            height: width
            radius: width / 2
            color: Theme.accent
            opacity: 0.15 + index * 0.1
            x: emptyRoot.width / 2 + (index === 0 ? -160 : index === 1 ? 140 : -100)
            y: emptyRoot.height / 2 + (index === 0 ? -120 : index === 1 ? -90 : 130)
            
            SequentialAnimation on y {
                loops: Animation.Infinite
                NumberAnimation { from: parent.y; to: parent.y - 30; duration: 3000 + index * 800; easing.type: Easing.InOutSine }
                NumberAnimation { from: parent.y - 30; to: parent.y; duration: 3000 + index * 800; easing.type: Easing.InOutSine }
            }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Theme.spaceL
        width: Math.min(parent.width * 0.85, 520)

        // ── Icon ──────────────────────────────────────────────────
        Item {
            width: 100
            height: 100
            Layout.alignment: Qt.AlignHCenter
            
            Rectangle {
                anchors.centerIn: parent
                width: 80; height: 80; radius: 40
                color: Theme.accent
                opacity: 0.15
                
                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 1.3; duration: 2500; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1.3; to: 1.0; duration: 2500; easing.type: Easing.InOutSine }
                }
            }
            Rectangle {
                anchors.centerIn: parent
                width: 64; height: 64; radius: 32
                color: Theme.accent
                opacity: 0.25
            }
            
            Text {
                anchors.centerIn: parent
                text: folderSelected ? "🔍" : "📂"
                font.pixelSize: 44
                opacity: 0.9
            }
        }

        // ── Title & Description ───────────────────────────────────
        ColumnLayout {
            spacing: Theme.spaceS
            Layout.fillWidth: true

            Text {
                text: folderSelected ? "Scan targets prepared" : "Scan targets"
                color: Theme.textPrimary
                font.pixelSize: Theme.fontDisplay
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }

            Text {
                text: folderSelected 
                      ? "Select " + scanTargets.length + " target" + (scanTargets.length > 1 ? "s" : "") + " to scan. Click 'Start Scan' to analyze."
                      : "Add folders or specific images to scan. We will find similar and exact duplicate photos to clean your storage."
                color: Theme.textSecondary
                font.pixelSize: Theme.fontHeader
                horizontalAlignment: Text.AlignHCenter
                lineHeight: 1.4
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        // ── Targets List Container (shown when targets exist) ─────
        Rectangle {
            id: targetsContainer
            visible: folderSelected
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(220, targetsList.contentHeight + 16)
            radius: Theme.radiusL
            color: Theme.bgGlass
            border.color: Theme.border
            border.width: 1
            clip: true

            ListView {
                id: targetsList
                anchors.fill: parent
                anchors.margins: 8
                model: emptyRoot.scanTargets
                spacing: 6
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    width: targetsList.width
                    height: 38
                    radius: Theme.radiusM
                    color: itemMouseArea.containsMouse ? Theme.bgHover : "transparent"
                    border.color: itemMouseArea.containsMouse ? Theme.borderLight : "transparent"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: Theme.spaceS

                        // Icon: folder or image file
                        Text {
                            text: {
                                var path = modelData.toLowerCase()
                                var isImg = path.endsWith(".jpg") || path.endsWith(".jpeg") || path.endsWith(".png") || path.endsWith(".webp") || path.endsWith(".heic")
                                return isImg ? "🖼" : "📁"
                            }
                            font.pixelSize: 13
                            Layout.alignment: Qt.AlignVCenter
                        }

                        // Short name
                        Text {
                            text: {
                                var parts = modelData.replace(/\\/g, "/").split("/")
                                return parts[parts.length - 1]
                            }
                            color: Theme.textPrimary
                            font.pixelSize: Theme.fontBody
                            font.bold: true
                            Layout.alignment: Qt.AlignVCenter
                        }

                        // Dimmed parent path
                        Text {
                            text: {
                                var parts = modelData.replace(/\\/g, "/").split("/")
                                if (parts.length > 2) {
                                    return ".../" + parts.slice(-3, -1).join("/")
                                }
                                return modelData
                            }
                            color: Theme.textMuted
                            font.pixelSize: Theme.fontSmall
                            elide: Text.ElideLeft
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                        }

                        // Remove Target Button
                        Item {
                            id: deleteBtn
                            width: 24
                            height: 24
                            Layout.alignment: Qt.AlignVCenter

                            Rectangle {
                                anchors.fill: parent
                                radius: 12
                                color: deleteMouse.containsMouse ? Theme.error : "transparent"
                                opacity: deleteMouse.containsMouse ? 0.15 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 100 } }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: deleteMouse.containsMouse ? Theme.error : Theme.textSecondary
                                font.pixelSize: 10
                                font.bold: true
                            }

                            MouseArea {
                                id: deleteMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (typeof scanController !== "undefined") {
                                        scanController.removeTarget(modelData)
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: itemMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        propagateComposedEvents: true
                    }
                }
            }
        }

        // ── Action Buttons Row (shown when NO targets exist) ──────
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.spaceM
            visible: !folderSelected

            // Import Button
            Rectangle {
                id: importBtn
                Layout.preferredWidth: 160
                Layout.preferredHeight: 44
                radius: 22
                color: importBtnMouse.containsMouse ? Theme.bgHover : "transparent"
                border.color: importBtnMouse.containsMouse ? Theme.accent : Theme.border
                border.width: 1
                scale: importBtnMouse.containsMouse ? 1.03 : 1.0
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    Text { text: "📁"; font.pixelSize: 16 }
                    Text {
                        text: "Import"
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontBody
                        font.bold: true
                    }
                }

                MouseArea {
                    id: importBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof scanController !== "undefined") {
                            scanController.addFolderTarget()
                        }
                    }
                }
            }
        }

        // ── Action Buttons Row (shown when targets DO exist) ─────
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.spaceM
            visible: folderSelected

            // Import More Button
            Rectangle {
                id: addMoreFolderBtn
                Layout.preferredWidth: 140
                Layout.preferredHeight: 38
                radius: 19
                color: addMoreFolderMouse.containsMouse ? Theme.bgHover : "transparent"
                border.color: Theme.border
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Text { text: "📁"; font.pixelSize: 12 }
                    Text {
                        text: "Import More"
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSmall
                        font.bold: true
                    }
                }

                MouseArea {
                    id: addMoreFolderMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof scanController !== "undefined") {
                            scanController.addFolderTarget()
                        }
                    }
                }
            }
        }

        // ── Big Primary "Start Scan" Button ───────────────────────
        Rectangle {
            id: primaryBtn
            visible: folderSelected
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 240
            Layout.preferredHeight: 52
            radius: 26
            
            property bool hovered: primaryBtnMouseArea.containsMouse
            scale: hovered ? 1.04 : 1.0
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

            gradient: Gradient {
                GradientStop { position: 0.0; color: primaryBtn.hovered ? "#4ADE80" : "#22C55E" }
                GradientStop { position: 1.0; color: primaryBtn.hovered ? "#22C55E" : "#16A34A" }
            }

            Text {
                anchors.centerIn: parent
                text: "Start Scan"
                color: Theme.textPrimary
                font.pixelSize: Theme.fontBody
                font.bold: true
            }

            MouseArea {
                id: primaryBtnMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (typeof scanController !== "undefined") {
                        if (typeof similarityController !== "undefined") {
                            similarityController.resetState()
                        }
                        scanController.startScan()
                    }
                }
            }
        }

        // ── Clear All Targets Button ─────────────────────────────
        Text {
            visible: folderSelected
            text: "Clear all targets"
            color: Theme.error
            font.pixelSize: Theme.fontSmall
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
            opacity: clearMouse.containsMouse ? 1.0 : 0.7

            Behavior on opacity {
                NumberAnimation { duration: 120 }
            }

            MouseArea {
                id: clearMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (typeof scanController !== "undefined") {
                        scanController.clearTargets()
                    }
                }
            }
        }
    }
}
