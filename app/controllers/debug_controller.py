"""QObject bridge exposing debug metrics to QML.

Provides a refreshable snapshot of all metrics via a single Slot call.
Visibility toggle and shortcut handling managed here.
"""

from PySide6.QtCore import QObject, Slot, Signal, Property

from app.services.debug_service import DebugService
from app.utils.logger import logger


class DebugController(QObject):
    """Controller for the internal debug/diagnostics panel.
    
    QML reads pre-computed values from get_snapshot().
    No raw DB models or computation leaks into QML.
    """

    visibleChanged = Signal()
    snapshotChanged = Signal()

    def __init__(self, debug_service: DebugService, parent=None):
        super().__init__(parent)
        self._debug_service = debug_service
        self._visible = False

    # ── Visibility ────────────────────────────────────────────────────

    @Property(bool, notify=visibleChanged)
    def visible(self) -> bool:
        return self._visible

    @Slot()
    def toggle(self):
        """Toggle debug panel visibility (Ctrl+Shift+D)."""
        self._visible = not self._visible
        self.visibleChanged.emit()
        logger.debug(f"Debug panel {'shown' if self._visible else 'hidden'}")

    # ── Snapshot ──────────────────────────────────────────────────────

    @Slot(result="QVariant")
    def getSnapshot(self):
        """Return a complete metrics dict for QML rendering.
        
        Called on-demand (panel open) or via lightweight timer.
        All computation happens in DebugService — QML only renders.
        """
        return self._debug_service.get_snapshot()
