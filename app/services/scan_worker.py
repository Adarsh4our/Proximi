from PySide6.QtCore import QObject, QRunnable, Signal, Slot

from app.services.scan_service import ScanService
from app.utils.logger import logger


class ScanWorkerSignals(QObject):
    """Signals for the scan worker.
    
    QRunnable doesn't inherit QObject, so signals must live in a
    separate QObject that bridges the worker thread to the main thread.
    """
    image_ready = Signal(str, str, str)   # original_path, thumbnail_path, file_name
    progress = Signal(int, int)           # current, total
    finished = Signal(int)                # total images processed
    error = Signal(str)                   # error message


class ScanWorker(QRunnable):
    """Background worker for folder scanning.
    
    Runs on QThreadPool to keep the UI thread responsive.
    Emits signals for each processed image so QML can update progressively.
    
    Supports future cancellation via cancel() / _cancelled flag.
    """

    def __init__(self, scan_service: ScanService, folder_path):
        super().__init__()
        self.scan_service = scan_service
        # Accept list or single string
        self.folder_path = folder_path if isinstance(folder_path, list) else [folder_path]
        self.signals = ScanWorkerSignals()
        self._cancelled = False
        self.setAutoDelete(True)


    def cancel(self):
        """Request cancellation of the running scan.
        
        The scan will stop at the next image boundary (not mid-image).
        """
        self._cancelled = True
        logger.info("Scan cancellation requested.")

    def _is_cancelled(self) -> bool:
        """Check if cancellation has been requested."""
        return self._cancelled

    @Slot()
    def run(self):
        """Execute the scan pipeline on a background thread."""
        try:
            logger.info(f"ScanWorker started for '{self.folder_path}'")

            total_processed = self.scan_service.scan_folder(
                folder_path=self.folder_path,
                on_image_ready=self._on_image_ready,
                on_progress=self._on_progress,
                is_cancelled=self._is_cancelled,
            )

            if self._cancelled:
                logger.info(f"ScanWorker cancelled after {total_processed} images.")
            else:
                logger.info(f"ScanWorker finished: {total_processed} images")

            self.signals.finished.emit(total_processed)

        except Exception as e:
            error_msg = f"Scan failed: {e}"
            logger.error(error_msg)
            self.signals.error.emit(error_msg)

    def _on_image_ready(self, original_path: str, thumbnail_path: str, file_name: str):
        """Relay individual image completion to the main thread via signal."""
        if not self._cancelled:
            self.signals.image_ready.emit(original_path, thumbnail_path, file_name)

    def _on_progress(self, current: int, total: int):
        """Relay scan progress to the main thread via signal."""
        if not self._cancelled:
            self.signals.progress.emit(current, total)
