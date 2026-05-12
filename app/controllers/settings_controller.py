from PySide6.QtCore import QObject, Slot, Signal, Property
from app.utils.logger import logger

class SettingsController(QObject):
    """QObject bridge for settings operations including similarity thresholds."""
    
    themeChanged = Signal(str)
    thresholdsChanged = Signal()
    settingsPanelVisibleChanged = Signal()
    
    def __init__(self, settings_service, parent=None):
        super().__init__(parent)
        self.settings_service = settings_service
        self._settings_panel_visible = False
        
        # Similarity threshold defaults
        self._phash_threshold = 12       # Max pHash Hamming distance (0-64, lower = stricter)
        self._ssim_threshold = 0.55      # Min SSIM composite score (0.0-1.0, higher = stricter)
        self._dhash_threshold = 18       # Max dHash Hamming distance (0-64, lower = stricter)
        self._histogram_threshold = 0.30 # Min histogram intersection (0.0-1.0, higher = stricter)

    # ── Settings Panel Visibility ─────────────────────────────────────

    @Property(bool, notify=settingsPanelVisibleChanged)
    def settingsPanelVisible(self) -> bool:
        return self._settings_panel_visible

    @Slot()
    def toggleSettingsPanel(self):
        self._settings_panel_visible = not self._settings_panel_visible
        self.settingsPanelVisibleChanged.emit()

    @Slot()
    def closeSettingsPanel(self):
        self._settings_panel_visible = False
        self.settingsPanelVisibleChanged.emit()

    # ── Threshold Properties ──────────────────────────────────────────

    @Property(int, notify=thresholdsChanged)
    def phashThreshold(self) -> int:
        return self._phash_threshold

    @Slot(int)
    def setPhashThreshold(self, value: int):
        self._phash_threshold = max(1, min(32, value))
        self.thresholdsChanged.emit()
        logger.debug(f"pHash threshold set to {self._phash_threshold}")

    @Property(float, notify=thresholdsChanged)
    def ssimThreshold(self) -> float:
        return self._ssim_threshold

    @Slot(float)
    def setSsimThreshold(self, value: float):
        self._ssim_threshold = max(0.1, min(0.99, round(value, 2)))
        self.thresholdsChanged.emit()
        logger.debug(f"SSIM threshold set to {self._ssim_threshold}")

    @Property(int, notify=thresholdsChanged)
    def dhashThreshold(self) -> int:
        return self._dhash_threshold

    @Slot(int)
    def setDhashThreshold(self, value: int):
        self._dhash_threshold = max(1, min(32, value))
        self.thresholdsChanged.emit()
        logger.debug(f"dHash threshold set to {self._dhash_threshold}")

    @Property(float, notify=thresholdsChanged)
    def histogramThreshold(self) -> float:
        return self._histogram_threshold

    @Slot(float)
    def setHistogramThreshold(self, value: float):
        self._histogram_threshold = max(0.05, min(0.95, round(value, 2)))
        self.thresholdsChanged.emit()
        logger.debug(f"Histogram threshold set to {self._histogram_threshold}")

    @Slot()
    def resetToDefaults(self):
        """Reset all thresholds to recommended defaults."""
        self._phash_threshold = 12
        self._ssim_threshold = 0.55
        self._dhash_threshold = 18
        self._histogram_threshold = 0.30
        self.thresholdsChanged.emit()
        logger.info("Similarity thresholds reset to defaults")

    # ── Legacy ────────────────────────────────────────────────────────

    @Slot(result=str)
    def getTheme(self):
        return self.settings_service.get_setting("theme", "dark")
        
    @Slot(str)
    def setTheme(self, theme_name):
        self.settings_service.set_setting("theme", theme_name)
        self.themeChanged.emit(theme_name)
