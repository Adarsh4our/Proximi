pragma Singleton
import QtQuick

QtObject {
    // Colors - Modern Minimal Dark Theme
    readonly property color bgApp: "#121212"
    readonly property color bgSidebar: "#1A1A1A"
    readonly property color bgPanel: "#242424"
    readonly property color bgHover: "#333333"

    readonly property color accent: "#4F46E5" // Indigo
    readonly property color accentHover: "#4338CA"
    readonly property color accentDisabled: "#312E81"
    readonly property color accentSubtle: "#3730A3"

    readonly property color textPrimary: "#FFFFFF"
    readonly property color textSecondary: "#A3A3A3"
    readonly property color textDisabled: "#525252"
    readonly property color textMuted: "#737373"

    readonly property color border: "#2E2E2E"
    readonly property color borderLight: "#3A3A3A"

    // Card colors
    readonly property color bgCard: "#1E1E1E"
    readonly property color bgCardHover: "#2A2A2A"
    readonly property color accentGlow: "#4F46E540" // accent with alpha

    // Status colors
    readonly property color success: "#22C55E"
    readonly property color warning: "#F59E0B"
    readonly property color error: "#EF4444"

    // Spacing
    readonly property int spaceXS: 4
    readonly property int spaceS: 8
    readonly property int spaceM: 16
    readonly property int spaceL: 24
    readonly property int spaceXL: 32

    // Radius
    readonly property int radiusS: 4
    readonly property int radiusM: 8
    readonly property int radiusL: 12

    // Typography
    readonly property int fontTitle: 20
    readonly property int fontHeader: 16
    readonly property int fontBody: 14
    readonly property int fontSmall: 12
    readonly property int fontCaption: 11

    // Grid
    readonly property int thumbnailSize: 180
    readonly property int gridSpacing: 8
}
