import os
import uuid
import shutil
from pathlib import Path
from typing import List, Dict, Any, Tuple, Optional
from app.database.trash_repository import TrashRepository
from app.services.folder_service import FolderService
from app.utils.logger import logger

class TrashService:
    """Manages moving files safely to and from the app-managed trash directory."""

    def __init__(self, repository: TrashRepository, folder_service: FolderService):
        self._repository = repository
        # Base trash directory (e.g., data/trash)
        self._trash_dir = folder_service.base_dir / "trash"
        self._trash_dir.mkdir(parents=True, exist_ok=True)

    def move_to_trash(self, 
                      files_to_trash: List[Dict[str, Any]], 
                      batch_id: str,
                      keeper_id: Optional[int] = None) -> Tuple[int, int]:
        """
        Move a list of files to the trash directory and record them in the DB.
        files_to_trash is a list of dicts:
        {
            "original_path": str,
            "group_id": int,
            "scan_session_id": int,
            "image_id": int
        }
        
        keeper_id: Explicitly passed to ensure the keeper image is never trashed, even if included.
        
        Returns:
            Tuple[int, int]: (number_of_files_successfully_moved, total_size_freed_bytes)
        """
        records_data = []
        moved_count = 0
        total_size_freed = 0
        
        for item in files_to_trash:
            # Rule 6: Explicit service-level keeper protection
            if keeper_id is not None and item["image_id"] == keeper_id:
                logger.critical(f"TrashService prevented deletion of keeper image {keeper_id}!")
                continue
                
            original_path = Path(item["original_path"])
            
            # Rule 1: Validate file exists
            if not original_path.exists() or not original_path.is_file():
                logger.warning(f"Cannot trash file that doesn't exist: {original_path}")
                continue
                
            try:
                # Calculate size before moving
                file_size = original_path.stat().st_size
                
                # Rule 3: Handle filename collisions safely
                # Format: original_filename__shortuuid.ext
                short_uuid = uuid.uuid4().hex[:8]
                trash_filename = f"{original_path.stem}__{short_uuid}{original_path.suffix}"
                trash_path = self._trash_dir / trash_filename
                
                # Move the file (preserves metadata on same filesystem)
                shutil.move(str(original_path), str(trash_path))
                
                # Prepare DB record
                records_data.append({
                    "original_path": str(original_path),
                    "trash_path": str(trash_path),
                    "group_id": item.get("group_id"),
                    "scan_session_id": item["scan_session_id"],
                    "image_id": item["image_id"],
                    "batch_id": batch_id
                })
                
                moved_count += 1
                total_size_freed += file_size
                logger.debug(f"Moved {original_path} to trash as {trash_filename}")
                
            except Exception as e:
                logger.error(f"Failed to move {original_path} to trash: {e}")
                
        # Persist to DB
        if records_data:
            self._repository.create_records(records_data)
            
        return moved_count, total_size_freed

    def restore_batch(self, batch_id: str) -> int:
        """
        Restores all files associated with a specific batch ID back to their original locations.
        Returns the number of successfully restored files.
        """
        records = self._repository.get_records_by_batch(batch_id)
        if not records:
            logger.info(f"No records found for batch {batch_id} to restore.")
            return 0
            
        restored_count = 0
        restored_ids = []
        
        for record in records:
            # Skip if already restored
            if record.restored_at is not None:
                continue
                
            trash_path = Path(record.trash_path)
            original_path = Path(record.original_path)
            
            if not trash_path.exists():
                logger.warning(f"Cannot restore: trash file missing: {trash_path}")
                continue
                
            try:
                # Ensure target directory exists (user might have deleted the folder!)
                original_path.parent.mkdir(parents=True, exist_ok=True)
                
                # If target file exists (collision on restore), we might need to append a suffix, 
                # but for now we'll do a safe copy/move and avoid overwriting blindly if possible.
                # However, since this is an "undo", usually the file was just removed from there.
                if original_path.exists():
                    logger.warning(f"File exists at restore destination: {original_path}. Overwriting...")
                    
                shutil.move(str(trash_path), str(original_path))
                restored_ids.append(record.id)
                restored_count += 1
                logger.debug(f"Restored {trash_path} to {original_path}")
                
            except Exception as e:
                logger.error(f"Failed to restore {trash_path} to {original_path}: {e}")
                
        # Update DB records
        if restored_ids:
            self._repository.mark_records_restored(restored_ids)
            
        return restored_count

    def get_stats(self) -> Dict[str, int]:
        """Get current trash statistics."""
        return self._repository.get_trash_stats()
