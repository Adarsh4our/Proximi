from PySide6.QtCore import QObject, Slot, Signal, Property, QThreadPool
from PySide6.QtWidgets import QFileDialog, QAbstractItemView

from pathlib import Path
import os
import json

from app.services.scan_service import ScanService
from app.services.scan_worker import ScanWorker
from app.services.duplicate_worker import DuplicateWorker
from app.services.duplicate_service import DuplicateService
from app.services.debug_service import DebugService
from app.database.image_repository import ImageRepository
from app.utils.logger import logger


class ImageViewModel:
    """Lightweight view-model transformation layer for QML-facing image data.
    
    Responsibilities:
    - Filesystem path to URI conversion (prevents QML file:/// hacks)
    - Formatting raw data for QML consumption
    """
    
    @staticmethod
    def from_image(img) -> dict:
        return {
            "imageId": img.id,
            "originalPath": Path(img.original_path).resolve().as_uri() if img.original_path else "",
            "thumbnailPath": Path(img.thumbnail_path).resolve().as_uri() if img.thumbnail_path else "",
            "fileName": img.file_name,
            "width": img.width or 0,
            "height": img.height or 0,
            "fileSize": img.file_size or 0,
            "modifiedAt": img.modified_at.timestamp() if img.modified_at else 0,
            "displayRotation": getattr(img, 'display_rotation', 0) or 0
        }
    
    @staticmethod
    def from_raw(original_path: str, thumbnail_path: str, file_name: str) -> dict:
        return {
            "originalPath": Path(original_path).resolve().as_uri() if original_path else "",
            "thumbnailPath": Path(thumbnail_path).resolve().as_uri() if thumbnail_path else "",
            "fileName": file_name,
        }


class ScanController(QObject):
    """QObject bridge for folder selection and scan operations.
    
    Manages the scan lifecycle: folder selection → scan execution → progress reporting.
    All heavy work runs on QThreadPool via ScanWorker.
    
    When a face_controller is provided, the scan automatically:
    1. Pre-warms the ML model during the scan (overlapping the ~40s init)
    2. Auto-triggers face detection as soon as the scan completes
    """

    # ── Signals ───────────────────────────────────────────────────────
    currentFolderChanged = Signal()
    scanTargetsChanged = Signal()
    scanStateChanged = Signal()
    scanProgressChanged = Signal()
    scannedCountChanged = Signal()
    totalImagesChanged = Signal()
    hasScannedCurrentFolderChanged = Signal()
    scanStarted = Signal()
    imageReady = Signal(int, str, str, str)  # image_id, original_path, thumbnail_path, file_name
    scanFinished = Signal(int)          # total processed

    # Duplicate Removal Signals
    duplicateRemovalStarted = Signal()
    duplicateRemovalProgress = Signal(int)
    duplicateRemovalFinished = Signal(list) # list of removed original_paths
    duplicateRemovalError = Signal(str)
    isRemovingDuplicatesChanged = Signal()

    def __init__(self, scan_service: ScanService, duplicate_service: DuplicateService, image_repository: ImageRepository, debug_service: DebugService = None, settings_controller=None, parent=None):
        super().__init__(parent)
        self._scan_service = scan_service
        self._duplicate_service = duplicate_service
        self._image_repository = image_repository
        self._debug_service = debug_service
        self._settings_controller = settings_controller
        self._scan_targets = []        # list of strings (folders/files)
        self._scan_state = "empty"     # empty | scanning | loaded | restored
        self._scan_progress = 0        # 0-100
        self._scanned_count = 0
        self._total_images = 0
        self._has_scanned_current_folder = False
        self._worker = None
        self._duplicate_worker = None
        self._is_removing_duplicates = False
        self._duplicate_progress = 0

    # ── Properties (exposed to QML) ───────────────────────────────────

    @Property(str, notify=currentFolderChanged)
    def currentFolder(self) -> str:
        if not self._scan_targets:
            return ""
        if len(self._scan_targets) == 1:
            return self._scan_targets[0]
        return os.path.commonpath(self._scan_targets)

    @Property(list, notify=scanTargetsChanged)
    def scanTargets(self) -> list:
        return self._scan_targets

    @Property(str, notify=scanStateChanged)
    def scanState(self) -> str:
        return self._scan_state

    @Property(int, notify=scanProgressChanged)
    def scanProgress(self) -> int:
        return self._scan_progress

    @Property(int, notify=scannedCountChanged)
    def scannedCount(self) -> int:
        return self._scanned_count

    @Property(int, notify=totalImagesChanged)
    def totalImages(self) -> int:
        return self._total_images

    @Property(bool, notify=hasScannedCurrentFolderChanged)
    def hasScannedCurrentFolder(self) -> bool:
        return self._has_scanned_current_folder

    @Property(bool, notify=isRemovingDuplicatesChanged)
    def isRemovingDuplicates(self) -> bool:
        return self._is_removing_duplicates

    @Property(int, notify=duplicateRemovalProgress)
    def duplicateProgress(self) -> int:
        return self._duplicate_progress

    # ── Slots (callable from QML) ─────────────────────────────────────

    @Slot()
    def selectFolder(self):
        """For compatibility: Opens a folder picker and adds to targets."""
        self.addFolderTarget()

    @Slot()
    @Slot()
    @Slot()
    def addFolderTarget(self):
        """Open native-looking folder picker and allow multiple directory selection."""
        dialog = QFileDialog()
        dialog.setWindowTitle("Select Folders to Scan")
        dialog.setFileMode(QFileDialog.FileMode.Directory)
        dialog.setOption(QFileDialog.Option.ShowDirsOnly, True)
        dialog.setOption(QFileDialog.Option.DontUseNativeDialog, True)
        
        # Hack to enable multiple selection on the QFileDialog
        views = dialog.findChildren(QAbstractItemView)
        for view in views:
            view.setSelectionMode(QAbstractItemView.SelectionMode.ExtendedSelection)
            
        if dialog.exec():
            folders = dialog.selectedFiles()
            new_targets = []
            for folder in folders:
                folder_path = str(Path(folder).resolve())
                if folder_path not in self._scan_targets:
                    self._scan_targets.append(folder_path)
                    new_targets.append(folder_path)
                    logger.info(f"Added folder target: {folder_path}")

            if new_targets:
                self.scanTargetsChanged.emit()
                self.currentFolderChanged.emit()
                self.startPartialScan(new_targets)  # Only scan the new folders

    @Slot()
    def addFileTargets(self):
        """Open a multi-select image file picker and add chosen files to scan targets."""
        dialog = QFileDialog()
        dialog.setWindowTitle("Select Image Files to Add")
        dialog.setFileMode(QFileDialog.FileMode.ExistingFiles)
        dialog.setNameFilter(
            "Images (*.jpg *.jpeg *.png *.webp *.heic *.heif *.bmp *.tiff *.tif *.gif *.raw *.cr2 *.nef *.arw *.dng)"
        )
        dialog.setOption(QFileDialog.Option.DontUseNativeDialog, False)

        if dialog.exec():
            files = dialog.selectedFiles()
            new_targets = []
            for file_path in files:
                resolved = str(Path(file_path).resolve())
                if resolved not in self._scan_targets:
                    self._scan_targets.append(resolved)
                    new_targets.append(resolved)
                    logger.info(f"Added file target: {resolved}")

            if new_targets:
                self.scanTargetsChanged.emit()
                self.currentFolderChanged.emit()
                self.startPartialScan(new_targets)  # Only scan the new files


    @Slot(str)
    def removeTarget(self, path: str):
        """Remove a target from scanTargets."""
        if path in self._scan_targets:
            self._scan_targets.remove(path)
            self.scanTargetsChanged.emit()
            self.currentFolderChanged.emit()
            logger.info(f"Removed target: {path}")

    @Slot()
    def clearTargets(self):
        """Clear all targets."""
        if self._scan_targets:
            self._scan_targets = []
            self.scanTargetsChanged.emit()
            self.currentFolderChanged.emit()
            logger.info("Cleared all scan targets.")

    @Slot(result=bool)
    def saveSessionAs(self):
        """Save current scan targets to a file."""
        if not self._scan_targets:
            logger.warning("No targets to save.")
            return False
            
        dialog = QFileDialog()
        dialog.setOption(QFileDialog.Option.DontUseNativeDialog, False)
        file_path, _ = dialog.getSaveFileName(
            None,
            "Save Session As...",
            "",
            "Proximi Session (*.pxm *.json);;All Files (*)"
        )
        if file_path:
            try:
                if not file_path.endswith('.pxm') and not file_path.endswith('.json'):
                    file_path += '.pxm'
                with open(file_path, 'w', encoding='utf-8') as f:
                    json.dump({"version": 1, "targets": self._scan_targets}, f, indent=4)
                logger.info(f"Saved session to {file_path}")
                return True
            except Exception as e:
                logger.error(f"Failed to save session: {e}")
                return False
        return False

    @Slot()
    def loadSession(self):
        """Load scan targets from a file and start scanning."""
        dialog = QFileDialog()
        dialog.setOption(QFileDialog.Option.DontUseNativeDialog, False)
        file_path, _ = dialog.getOpenFileName(
            None,
            "Load Session...",
            "",
            "Proximi Session (*.pxm *.json);;All Files (*)"
        )
        if file_path:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    targets = data.get("targets", [])
                    if targets:
                        self._scan_targets = targets
                        self.scanTargetsChanged.emit()
                        self.currentFolderChanged.emit()
                        logger.info(f"Loaded session from {file_path} with {len(targets)} targets")
                        self.startScan()
                    else:
                        logger.warning(f"No targets found in session file {file_path}")
            except Exception as e:
                logger.error(f"Failed to load session: {e}")


    @Slot()
    def startScan(self):
        """Launch a full async scan — clears DB and rescans all targets."""
        if not self._scan_targets:
            logger.warning("No targets selected — cannot start scan.")
            return

        if self._scan_state == "scanning":
            logger.warning("Scan already in progress.")
            return

        # Clear the database before starting a new scan to prevent mixing images from old folders
        from app.database.connection import db
        db.clear_database()

        self._start_scan_worker(self._scan_targets, partial=False)

    @Slot(list)
    def startPartialScan(self, new_targets: list):
        """Scan only the newly added targets, appending to the existing grid without clearing the DB."""
        if not new_targets:
            return

        if self._scan_state == "scanning":
            logger.warning("Scan already in progress — queuing partial scan after current finishes.")
            return

        logger.info(f"Starting partial scan for new targets: {new_targets}")
        self._start_scan_worker(new_targets, partial=True)

    def _start_scan_worker(self, targets: list, partial: bool = False):
        """Internal: set up and launch a ScanWorker for the given targets."""
        # Reset progress state (keep existing scanned count if partial)
        self._scan_state = "scanning"
        self._scan_progress = 0
        if not partial:
            self._scanned_count = 0
            self._total_images = 0
        self.scanStateChanged.emit()
        self.scanProgressChanged.emit()
        if not partial:
            self.scannedCountChanged.emit()
            self.totalImagesChanged.emit()
            self.scanStarted.emit()

        self._worker = ScanWorker(self._scan_service, targets)
        self._worker.signals.image_ready.connect(self._on_image_ready)
        self._worker.signals.progress.connect(
            self._on_partial_progress if partial else self._on_progress
        )
        self._worker.signals.finished.connect(self._on_finished)
        self._worker.signals.error.connect(self._on_error)

        QThreadPool.globalInstance().start(self._worker)
        logger.info(f"{'Partial' if partial else 'Full'} scan started for targets: {targets}")

    @Slot()
    def removeExactDuplicates(self):
        """Finds and removes exact duplicates in the background."""
        if self._is_removing_duplicates:
            logger.warning("Duplicate removal already in progress.")
            return

        self._is_removing_duplicates = True
        self._duplicate_progress = 0
        self.isRemovingDuplicatesChanged.emit()
        self.duplicateRemovalProgress.emit(0)
        self.duplicateRemovalStarted.emit()

        self._duplicate_worker = DuplicateWorker(self._duplicate_service)
        self._duplicate_worker.signals.progress.connect(self._on_duplicate_progress)
        self._duplicate_worker.signals.finished.connect(self._on_duplicate_finished)
        self._duplicate_worker.signals.error.connect(self._on_duplicate_error)

        QThreadPool.globalInstance().start(self._duplicate_worker)
        logger.info("Duplicate removal started.")

    @Slot(result=int)
    def getStoredImageCount(self):
        """Return total images stored in database (for startup)."""
        return self._image_repository.get_image_count()

    @Slot(result=list)
    def getStoredImages(self):
        """Return all stored images as list of dicts (for startup loading)."""
        images = self._image_repository.get_all_images()
        result = []
        for img in images:
            if img.thumbnail_path:
                vm = ImageViewModel.from_image(img)
                result.append(vm)
        return result

    @Slot()
    def loadPersistedSession(self):
        """Restore the previous scan session on app startup (M12)."""
        # Check persistence flag via settings controller
        persistence_on = False
        if self._settings_controller is not None:
            try:
                persistence_on = self._settings_controller.sessionPersistence
            except Exception:
                pass

        if not persistence_on:
            logger.debug("loadPersistedSession: persistence OFF — nothing to restore.")
            return

        images = self._image_repository.get_all_images()
        if not images:
            logger.info("loadPersistedSession: no stored images found.")
            return

        logger.info(f"Restoring persisted session: {len(images)} images.")

        # Restore the folder path from the last scan session
        last_folder = self._image_repository.get_latest_scan_folder()
        if last_folder:
            if ";" in last_folder:
                self._scan_targets = [p.strip() for p in last_folder.split(";") if p.strip()]
            else:
                self._scan_targets = [last_folder] if last_folder else []
            self._has_scanned_current_folder = True
            self.currentFolderChanged.emit()
            self.scanTargetsChanged.emit()
            self.hasScannedCurrentFolderChanged.emit()

        # Emit each image into the grid
        for img in images:
            if img.thumbnail_path:
                vm = ImageViewModel.from_image(img)
                self.imageReady.emit(
                    vm["imageId"],
                    vm["originalPath"],
                    vm["thumbnailPath"],
                    vm["fileName"],
                )

        # Update counts
        self._scanned_count = len(images)
        self._total_images = len(images)
        self._scan_state = "loaded"
        self.scannedCountChanged.emit()
        self.totalImagesChanged.emit()
        self.scanStateChanged.emit()

        logger.info("Persisted session restored successfully.")

    # ── Internal Signal Handlers ──────────────────────────────────────

    def _on_image_ready(self, original_path: str, thumbnail_path: str, file_name: str):
        """Relay image_ready from worker to QML via view-model transformation."""
        self._scanned_count += 1
        self.scannedCountChanged.emit()
        
        vm = ImageViewModel.from_raw(original_path, thumbnail_path, file_name)
        # imageId is not available during fast streaming — use -1 for main grid;
        # GroupReviewView gets proper imageIds from group data separately.
        self.imageReady.emit(-1, vm["originalPath"], vm["thumbnailPath"], vm["fileName"])

    def _on_progress(self, current: int, total: int):
        """Update progress for a full scan."""
        self._total_images = total
        self._scan_progress = int((current / total) * 100) if total > 0 else 0
        self.totalImagesChanged.emit()
        self.scanProgressChanged.emit()

    def _on_partial_progress(self, current: int, total: int):
        """Update progress for a partial scan — total counts accumulate on top of existing."""
        self._total_images = self._scanned_count + total
        new_progress = int((current / total) * 100) if total > 0 else 0
        self._scan_progress = new_progress
        self.totalImagesChanged.emit()
        self.scanProgressChanged.emit()

    def _on_finished(self, total_processed: int):
        """Handle scan completion. Auto-triggers face detection if available."""
        self._scan_state = "loaded"
        self._scan_progress = 100
        self._has_scanned_current_folder = True
        self._worker = None
        if self._debug_service:
            self._debug_service.scan_completed()
        self.hasScannedCurrentFolderChanged.emit()
        self.scanStateChanged.emit()
        self.scanProgressChanged.emit()
        self.scanFinished.emit(total_processed)
        logger.info(f"Scan finished: {total_processed} images processed.")


    def _on_error(self, error_msg: str):
        """Handle scan failure."""
        self._scan_state = "loaded"  # Go to loaded state (may have partial results)
        self._worker = None
        if self._debug_service:
            self._debug_service.scan_completed()
        self.scanStateChanged.emit()
        logger.error(f"Scan error: {error_msg}")

    # ── Duplicate Removal Handlers ────────────────────────────────────

    def _on_duplicate_progress(self, current: int, total: int):
        self._duplicate_progress = current
        self.duplicateRemovalProgress.emit(current)

    def _on_duplicate_finished(self, removed_paths: list):
        self._is_removing_duplicates = False
        self._duplicate_worker = None
        self.isRemovingDuplicatesChanged.emit()
        self.duplicateRemovalFinished.emit(removed_paths)
        
        # Also refresh totalImages and scannedCount to reflect the new state
        remaining = self._image_repository.get_image_count()
        self._total_images = remaining
        self._scanned_count = remaining
        self.totalImagesChanged.emit()
        self.scannedCountChanged.emit()

    def _on_duplicate_error(self, error_msg: str):
        self._is_removing_duplicates = False
        self._duplicate_worker = None
        self.isRemovingDuplicatesChanged.emit()
        self.duplicateRemovalError.emit(error_msg)
        logger.error(f"Duplicate removal error: {error_msg}")
