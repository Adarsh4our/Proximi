import uuid
import imagehash
from PIL import Image as PILImage
from collections import defaultdict
from pathlib import Path
from typing import Callable, Tuple, Optional

from app.database.image_repository import ImageRepository
from app.services.trash_service import TrashService
from app.utils.logger import logger

class DuplicateService:
    def __init__(self, image_repository: ImageRepository, trash_service: TrashService):
        self.image_repository = image_repository
        self.trash_service = trash_service

    def remove_exact_duplicates(self, on_progress: Callable[[int, int], None] = None, is_cancelled: Callable[[], bool] = None) -> list[str]:
        """
        Finds exact perceptual duplicates, keeps the best one (largest file size),
        moves the rest to trash, and removes them from the database.
        Returns the list of original_paths of the removed images.
        """
        # 1. Fetch all images
        images = self.image_repository.get_all_images()
        if not images:
            return []
            
        total_images = len(images)
        
        # 2. Compute missing hashes
        logger.info(f"Computing hashes for {total_images} images for exact duplicate detection...")
        for i, img in enumerate(images):
            if is_cancelled and is_cancelled():
                return []
                
            if not img.phash or not img.dhash:
                ph, dh = self._compute_hashes(img)
                if ph and dh:
                    self.image_repository.update_hashes(img.id, ph, dh)
                    img.phash = ph
                    img.dhash = dh
                    
            if on_progress:
                on_progress(int((i / total_images) * 50), 100) # Stage 1 takes 50%
                
        # Filter images that successfully got hashes
        hashed_images = [img for img in images if img.phash and img.dhash]
        
        # 3. Group by (phash, dhash)
        hash_groups = defaultdict(list)
        for img in hashed_images:
            hash_groups[(img.phash, img.dhash)].append(img)
            
        # 4. Identify duplicates to remove
        files_to_trash = []
        ids_to_delete = []
        removed_paths = []
        batch_id = f"exact_dup_{uuid.uuid4().hex[:8]}"
        
        groups_with_dups = [group for group in hash_groups.values() if len(group) > 1]
        total_dup_groups = len(groups_with_dups)
        
        for i, group in enumerate(groups_with_dups):
            if is_cancelled and is_cancelled():
                break
                
            # Sort by file_size descending so we keep the largest one
            group.sort(key=lambda x: x.file_size, reverse=True)
            keeper = group[0]
            duplicates = group[1:]
            
            for dup in duplicates:
                files_to_trash.append({
                    "original_path": dup.original_path,
                    "group_id": None,
                    "scan_session_id": dup.scan_session_id,
                    "image_id": dup.id
                })
                ids_to_delete.append(dup.id)
                removed_paths.append(dup.original_path)
                
            if on_progress:
                progress_pct = 50 + int((i / max(1, total_dup_groups)) * 50)
                on_progress(progress_pct, 100)
                
        # 5. Move to trash and delete from DB
        if files_to_trash:
            moved, _ = self.trash_service.move_to_trash(files_to_trash, batch_id)
            if ids_to_delete:
                self.image_repository.delete_images(ids_to_delete)
            logger.info(f"Removed {moved} exact duplicates.")
            
        if on_progress:
            on_progress(100, 100)
            
        return removed_paths

    def _compute_hashes(self, img) -> Tuple[Optional[str], Optional[str]]:
        path = img.thumbnail_path if img.thumbnail_path and Path(img.thumbnail_path).exists() else img.original_path
        try:
            with PILImage.open(path) as pil_img:
                pil_img = pil_img.convert('RGB')
                ph = str(imagehash.phash(pil_img))
                dh = str(imagehash.dhash(pil_img))
                return ph, dh
        except Exception as e:
            logger.error(f"Failed to hash {path}: {e}")
            return None, None
