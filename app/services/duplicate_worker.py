from PySide6.QtCore import QObject, QRunnable, Signal
from app.services.duplicate_service import DuplicateService
from app.utils.logger import logger

class DuplicateSignals(QObject):
    progress = Signal(int, int)        # current_pct, total_pct
    finished = Signal(list)            # list of original_paths removed
    error = Signal(str)

class DuplicateWorker(QRunnable):
    """Background worker for removing exact duplicates."""

    def __init__(self, duplicate_service: DuplicateService):
        super().__init__()
        self.duplicate_service = duplicate_service
        self.signals = DuplicateSignals()
        self._cancelled = False

    def cancel(self):
        self._cancelled = True

    def run(self):
        try:
            removed_paths = self.duplicate_service.remove_exact_duplicates(
                on_progress=lambda current, total: self.signals.progress.emit(current, total),
                is_cancelled=lambda: self._cancelled
            )
            
            if self._cancelled:
                logger.info("Duplicate worker cancelled.")
                self.signals.error.emit("Duplicate removal cancelled.")
            else:
                self.signals.finished.emit(removed_paths)
                
        except Exception as e:
            error_msg = f"Duplicate processing failed: {e}"
            logger.error(error_msg)
            self.signals.error.emit(error_msg)
