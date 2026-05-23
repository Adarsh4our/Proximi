from PySide6.QtCore import QObject, Slot, Signal, Property
from app.utils.logger import logger


class SettingsController(QObject):
    """QObject bridge for all application settings.

    Reads initial values from SettingsService (persisted JSON) and writes back
    on every change so settings survive app restarts.
    """

    # ── Signals ────────────────────────────────────────────────────────
    themeChanged = Signal(str)
    thresholdsChanged = Signal()
    settingsPanelVisibleChanged = Signal()
    sessionPersistenceChanged = Signal()
    onboardingCompletedChanged = Signal()
    thumbnailQualityChanged = Signal()

    def __init__(self, settings_service, parent=None):
        super().__init__(parent)
        self._svc = settings_service
        self._settings_panel_visible = False

        # ── Load persisted values ──────────────────────────────────────
        sim = self._svc.get("similarity", {})
        self._phash_threshold     = sim.get("phash_threshold",     12)
        self._ssim_threshold      = sim.get("ssim_threshold",      0.55)
        self._dhash_threshold     = sim.get("dhash_threshold",     18)
        self._histogram_threshold = sim.get("histogram_threshold", 0.30)
        self._session_persistence = bool(self._svc.get("session_persistence", False))
        self._onboarding_completed = bool(self._svc.get("onboarding_completed", False))
        self._thumbnail_quality   = int(self._svc.get("thumbnail_quality", 85))

    # ── Settings Panel Visibility ──────────────────────────────────────

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

    # ── Similarity Threshold Properties ───────────────────────────────

    @Property(int, notify=thresholdsChanged)
    def phashThreshold(self) -> int:
        return self._phash_threshold

    @Slot(int)
    def setPhashThreshold(self, value: int):
        self._phash_threshold = max(1, min(32, value))
        self._svc.set_similarity("phash_threshold", self._phash_threshold)
        self.thresholdsChanged.emit()
        logger.debug(f"pHash threshold → {self._phash_threshold}")

    @Property(float, notify=thresholdsChanged)
    def ssimThreshold(self) -> float:
        return self._ssim_threshold

    @Slot(float)
    def setSsimThreshold(self, value: float):
        self._ssim_threshold = max(0.1, min(0.99, round(value, 2)))
        self._svc.set_similarity("ssim_threshold", self._ssim_threshold)
        self.thresholdsChanged.emit()
        logger.debug(f"SSIM threshold → {self._ssim_threshold}")

    @Property(int, notify=thresholdsChanged)
    def dhashThreshold(self) -> int:
        return self._dhash_threshold

    @Slot(int)
    def setDhashThreshold(self, value: int):
        self._dhash_threshold = max(1, min(32, value))
        self._svc.set_similarity("dhash_threshold", self._dhash_threshold)
        self.thresholdsChanged.emit()
        logger.debug(f"dHash threshold → {self._dhash_threshold}")

    @Property(float, notify=thresholdsChanged)
    def histogramThreshold(self) -> float:
        return self._histogram_threshold

    @Slot(float)
    def setHistogramThreshold(self, value: float):
        self._histogram_threshold = max(0.05, min(0.95, round(value, 2)))
        self._svc.set_similarity("histogram_threshold", self._histogram_threshold)
        self.thresholdsChanged.emit()
        logger.debug(f"Histogram threshold → {self._histogram_threshold}")

    @Slot()
    def resetToDefaults(self):
        """Reset all thresholds to recommended defaults and persist."""
        self._svc.reset_similarity_to_defaults()
        sim = self._svc.get("similarity", {})
        self._phash_threshold     = sim.get("phash_threshold",     12)
        self._ssim_threshold      = sim.get("ssim_threshold",      0.55)
        self._dhash_threshold     = sim.get("dhash_threshold",     18)
        self._histogram_threshold = sim.get("histogram_threshold", 0.30)
        self.thresholdsChanged.emit()
        logger.info("Similarity thresholds reset to defaults.")

    # ── General Settings Properties ────────────────────────────────────

    @Property(int, notify=thumbnailQualityChanged)
    def thumbnailQuality(self) -> int:
        return self._thumbnail_quality

    @Slot(int)
    def setThumbnailQuality(self, value: int):
        self._thumbnail_quality = max(50, min(100, value))
        self._svc.set("thumbnail_quality", self._thumbnail_quality)
        self.thumbnailQualityChanged.emit()
        logger.debug(f"Thumbnail quality → {self._thumbnail_quality}")

    # ── Session Persistence ────────────────────────────────────────────

    @Property(bool, notify=sessionPersistenceChanged)
    def sessionPersistence(self) -> bool:
        return self._session_persistence

    @Slot(bool)
    def setSessionPersistence(self, value: bool):
        self._session_persistence = bool(value)
        self._svc.set("session_persistence", self._session_persistence)
        self.sessionPersistenceChanged.emit()
        logger.info(f"Session persistence → {self._session_persistence}")

    # ── Onboarding ─────────────────────────────────────────────────────

    @Property(bool, notify=onboardingCompletedChanged)
    def onboardingCompleted(self) -> bool:
        return self._onboarding_completed

    @Slot()
    def completeOnboarding(self):
        """Mark onboarding as done and persist so it never shows again."""
        self._onboarding_completed = True
        self._svc.set("onboarding_completed", True)
        self.onboardingCompletedChanged.emit()
        logger.info("Onboarding marked as completed.")

    @Slot()
    def resetOnboarding(self):
        """Re-enable onboarding (used by Help → Show Tutorial)."""
        self._onboarding_completed = False
        self._svc.set("onboarding_completed", False)
        self.onboardingCompletedChanged.emit()
        logger.info("Onboarding reset — will show on next trigger.")

    # ── Legacy ─────────────────────────────────────────────────────────

    @Slot(result=str)
    def getTheme(self):
        return self._svc.get("theme", "dark")

    @Slot(str)
    def setTheme(self, theme_name):
        self._svc.set("theme", theme_name)
        self.themeChanged.emit(theme_name)
