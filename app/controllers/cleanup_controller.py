import uuid
from PySide6.QtCore import QObject, Slot, Signal, Property
from app.services.trash_service import TrashService
from app.controllers.similarity_controller import SimilarityController
from app.services.debug_service import DebugService
from app.utils.logger import logger
from urllib.request import url2pathname
from urllib.parse import urlparse

class CleanupController(QObject):
    """QObject bridge for executing cleanup and managing selection states."""

    selectionStateChanged = Signal()
    keeperCountChanged = Signal()
    rejectedCountChanged = Signal()
    canUndoChanged = Signal()
    lastActionChanged = Signal()
    totalDeletedChanged = Signal()
    
    # Emitted when an action is completed, carrying a status message for the UI
    actionCompleted = Signal(str)

    def __init__(self, 
                 trash_service: TrashService, 
                 similarity_controller: SimilarityController,
                 debug_service: DebugService = None,
                 parent=None):
        super().__init__(parent)
        self._trash_service = trash_service
        self._similarity_controller = similarity_controller
        self._debug_service = debug_service
        
        self._selection_state = {}  # {imageId: "keeper" | "rejected" | "unselected"}
        self._group_states = {}     # {group_index: selection_state_dict} — per-group persistence
        self._current_group_idx = -1
        self._last_batch_id = None
        self._last_action_msg = ""
        self._total_deleted = 0
        
        # When similarity controller changes group, auto-select a keeper
        self._similarity_controller.currentGroupIndexChanged.connect(self._on_group_changed)

    # ── Properties ────────────────────────────────────────────────────

    @Property(dict, notify=selectionStateChanged)
    def selectionState(self) -> dict:
        return self._selection_state

    @Property(int, notify=keeperCountChanged)
    def keeperCount(self) -> int:
        return sum(1 for state in self._selection_state.values() if state == "keeper")

    @Property(int, notify=rejectedCountChanged)
    def rejectedCount(self) -> int:
        return sum(1 for state in self._selection_state.values() if state == "rejected")

    @Property(bool, notify=canUndoChanged)
    def canUndo(self) -> bool:
        return self._last_batch_id is not None

    @Property(str, notify=lastActionChanged)
    def lastAction(self) -> str:
        return self._last_action_msg

    @Property(int, notify=totalDeletedChanged)
    def totalDeleted(self) -> int:
        return self._total_deleted

    # ── Slots ─────────────────────────────────────────────────────────

    @Slot(int)
    def toggleSelection(self, image_id: int):
        """Single click action: simple select/focus (unselected <-> rejected)."""
        img_id_str = str(image_id)
        current_state = self._selection_state.get(img_id_str, "unselected")
        if current_state == "rejected":
            self._selection_state[img_id_str] = "unselected"
        else:
            self._selection_state[img_id_str] = "rejected"
        self._selection_state = self._selection_state.copy()
        self._emit_selection_changes()

    @Slot(int)
    def setKeeper(self, image_id: int):
        """Set this image as the keeper. Unsets any existing keepers in the group."""
        group_data = self._similarity_controller.getCurrentGroupData()
        if not group_data or "images" not in group_data:
            return
            
        img_id_str = str(image_id)
        for img in group_data["images"]:
            current_id_str = str(img["imageId"])
            if current_id_str == img_id_str:
                self._selection_state[current_id_str] = "keeper"
            elif self._selection_state.get(current_id_str) == "keeper":
                self._selection_state[current_id_str] = "unselected"
                
        self._selection_state = self._selection_state.copy()
        self._emit_selection_changes()

    @Slot()
    def selectAllExceptKeeper(self):
        """Mark all non-keepers as rejected."""
        group_data = self._similarity_controller.getCurrentGroupData()
        if not group_data or "images" not in group_data:
            return
            
        for img in group_data["images"]:
            current_id_str = str(img["imageId"])
            if self._selection_state.get(current_id_str) != "keeper":
                self._selection_state[current_id_str] = "rejected"
                
        self._selection_state = self._selection_state.copy()
        self._emit_selection_changes()

    @Slot()
    def clearSelection(self):
        """Reset all selections."""
        self._selection_state.clear()
        self._selection_state = self._selection_state.copy()
        self._emit_selection_changes()

    @Slot()
    def executeCleanup(self):
        """Moves all rejected files to the trash and auto-advances if successful."""
        group_data = self._similarity_controller.getCurrentGroupData()
        if not group_data or "images" not in group_data:
            return
            
        files_to_trash = []
        rejected_count = 0
        
        # We need the group index to know which group we're operating on
        group_index = self._similarity_controller.currentGroupIndex
        # But we need the actual DB group_id, let's use the scan_session_id = 1 assumption for now
        # Actually, let's just extract original_path from the ViewModel
        
        for img in group_data["images"]:
            img_id = img["imageId"]
            img_id_str = str(img_id)
            state = self._selection_state.get(img_id_str, "unselected")
            
            # Rule 6: Keeper protection
            if state == "keeper":
                continue
                
            if state == "rejected":
                uri = img["originalPath"]
                # Convert file:// uri back to path
                parsed = urlparse(uri)
                path_str = url2pathname(parsed.path)
                
                # Strip leading slash on windows if present like \C:\...
                if path_str.startswith("\\") and ":" in path_str:
                    path_str = path_str[1:]
                    
                files_to_trash.append({
                    "original_path": path_str,
                    "group_id": None, # Optional, skip for now
                    "scan_session_id": 1,
                    "image_id": img_id
                })
                rejected_count += 1
                
        if not files_to_trash:
            logger.info("Execute cleanup called but no images are rejected.")
            self.actionCompleted.emit("No images selected for cleanup.")
            return
            
        # Extract keeper ID to pass down to service layer for explicit protection
        keeper_id = None
        for k, v in self._selection_state.items():
            if v == "keeper":
                keeper_id = k
                break
            
        batch_id = uuid.uuid4().hex
        
        try:
            moved_count, freed_bytes = self._trash_service.move_to_trash(files_to_trash, batch_id, keeper_id=keeper_id)
            
            if moved_count > 0:
                self._last_batch_id = batch_id
                mb_freed = freed_bytes / (1024 * 1024)
                msg = f"Moved {moved_count} image{'s' if moved_count > 1 else ''} to trash. Freed {mb_freed:.1f} MB."
                self._last_action_msg = msg
                logger.info(msg)
                
                self.canUndoChanged.emit()
                self.lastActionChanged.emit()
                self.actionCompleted.emit(msg)
                
                self._total_deleted += moved_count
                self.totalDeletedChanged.emit()
                
                if self._debug_service:
                    self._debug_service.cleanup_executed(moved_count)
                
                # Save cleaned state for this group before auto-advancing
                current_idx = self._similarity_controller.currentGroupIndex
                self._group_states[current_idx] = self._selection_state.copy()
                
                # Auto-advance (Rule 1)
                self._similarity_controller.nextGroup()
            else:
                self.actionCompleted.emit("Failed to move files to trash.")
                
        except Exception as e:
            logger.error(f"Cleanup execution failed: {e}")
            self.actionCompleted.emit("Cleanup failed due to an error.")

    @Slot()
    def undoLastCleanup(self):
        """Restores the last cleanup batch."""
        if not self._last_batch_id:
            return
            
        try:
            restored_count = self._trash_service.restore_batch(self._last_batch_id)
            msg = f"Undid cleanup. Restored {restored_count} image{'s' if restored_count > 1 else ''}."
            self._last_action_msg = msg
            logger.info(msg)
            
            self._last_batch_id = None
            self.canUndoChanged.emit()
            self.lastActionChanged.emit()
            self.actionCompleted.emit(msg)
            
            if self._debug_service:
                self._debug_service.undo_executed(restored_count)
                
            # Optionally, we might want to navigate back to the previous group
            self._similarity_controller.previousGroup()
            
        except Exception as e:
            logger.error(f"Undo failed: {e}")
            self.actionCompleted.emit("Undo failed due to an error.")

    # ── Internal ──────────────────────────────────────────────────────
    
    def _on_group_changed(self):
        """When navigating to a new group, save current state and restore/create state for new group."""
        new_idx = self._similarity_controller.currentGroupIndex
        
        # Save current group's state before switching
        if self._current_group_idx >= 0:
            self._group_states[self._current_group_idx] = self._selection_state.copy()
        
        self._current_group_idx = new_idx
        
        # Restore if revisiting a previously visited group
        if new_idx in self._group_states:
            self._selection_state = self._group_states[new_idx].copy()
            self._emit_selection_changes()
            return
        
        # Fresh group — auto-select best image as keeper
        self._selection_state = {}
        
        group_data = self._similarity_controller.getCurrentGroupData()
        if not group_data or "images" not in group_data:
            self._emit_selection_changes()
            return
            
        # Heuristic: largest resolution, tiebreaker file size, tiebreaker earliest modified
        best_img = None
        best_score = (-1, -1, float('inf'))
        
        for img in group_data["images"]:
            res = img.get("width", 0) * img.get("height", 0)
            size = img.get("fileSize", 0)
            modified = img.get("modifiedAt", 0)
            
            score = (res, size, modified)
            
            if best_img is None:
                best_img = img
                best_score = score
            else:
                if score[0] > best_score[0]:
                    best_img = img
                    best_score = score
                elif score[0] == best_score[0]:
                    if score[1] > best_score[1]:
                        best_img = img
                        best_score = score
                    elif score[1] == best_score[1]:
                        if score[2] < best_score[2]:
                            best_img = img
                            best_score = score
                            
        if best_img:
            self._selection_state[str(best_img["imageId"])] = "keeper"
            
        self._selection_state = self._selection_state.copy()
        self._emit_selection_changes()

    def _emit_selection_changes(self):
        self.selectionStateChanged.emit()
        self.keeperCountChanged.emit()
        self.rejectedCountChanged.emit()
