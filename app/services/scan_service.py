from datetime import datetime
from pathlib import Path
from typing import Callable, Optional

from collections import Counter

from app.database.image_repository import ImageRepository
from app.services.thumbnail_service import ThumbnailService
from app.utils.logger import logger

# Supported image extensions
SUPPORTED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".heic"}


class ScanService:
    """Orchestrates folder scanning, thumbnail generation, and DB persistence.
    
    Pipeline order per image:
        1. Recursive discovery
        2. Metadata extraction (stat + dimensions)
        3. DB persistence (upsert image record)
        4. Thumbnail generation (Pillow → WEBP cache)
        5. Progressive UI update (via callback)
    """

    def __init__(self, image_repository: ImageRepository, thumbnail_service: ThumbnailService, debug_service=None):
        self.image_repository = image_repository
        self.thumbnail_service = thumbnail_service
        self._debug_service = debug_service

    def discover_images(self, folder_path: str) -> list[Path]:
        """Recursively discover supported image files in a folder.
        
        Returns:
            Sorted list of resolved Path objects for supported images.
        """
        folder = Path(folder_path)
        if not folder.is_dir():
            logger.error(f"Folder does not exist: {folder_path}")
            return []

        discovered = []
        skipped_extensions: Counter = Counter()
        total_files = 0

        for item in folder.rglob("*"):
            if not item.is_file():
                continue
            total_files += 1
            ext = item.suffix.lower()
            if ext in SUPPORTED_EXTENSIONS:
                discovered.append(item.resolve())
            else:
                skipped_extensions[ext] += 1

        # Sort for deterministic processing order
        discovered.sort()

        # Log results
        skipped_count = total_files - len(discovered)
        logger.info(f"Discovered {len(discovered)} supported images in '{folder_path}' "
                     f"(total files: {total_files}, skipped: {skipped_count})")
        if skipped_extensions:
            for ext, count in skipped_extensions.most_common():
                logger.info(f"  Skipped {count} files with extension '{ext}'")

        return discovered

    def process_single_image(
        self,
        image_path: Path,
        scan_session_id: int
    ) -> Optional[dict]:
        """Process a single image following the ordered pipeline:
        
        1. Metadata extraction (stat + dimensions)
        2. DB persistence (upsert)
        3. Thumbnail generation
        4. Update DB with thumbnail path
        
        Returns:
            Dict with keys (original_path, thumbnail_path, file_name) on success,
            or None on failure.
        """
        try:
            original_path = str(image_path)
            
            # ── Step 1: Metadata extraction ───────────────────────────
            stat = image_path.stat()
            file_size = stat.st_size
            modified_timestamp = stat.st_mtime
            modified_at = datetime.fromtimestamp(modified_timestamp)

            # Check if image already exists with same mtime (skip if unchanged)
            existing = self.image_repository.get_image_by_path(original_path)
            if existing and existing.modified_at == modified_at and existing.thumbnail_path:
                return {
                    "original_path": existing.original_path,
                    "thumbnail_path": existing.thumbnail_path,
                    "file_name": existing.file_name,
                    "skipped": True,
                }

            # Read dimensions (Pillow — opens file briefly, does not load full raster)
            width, height = self.thumbnail_service.get_image_dimensions(original_path)

            # ── Step 2: DB persistence (metadata first, thumbnail later) ──
            image_data = {
                "original_path": original_path,
                "file_name": image_path.name,
                "extension": image_path.suffix.lower(),
                "width": width,
                "height": height,
                "file_size": file_size,
                "modified_at": modified_at,
                "thumbnail_path": None,  # Set after thumbnail generation
                "scan_session_id": scan_session_id,
            }
            self.image_repository.upsert_image(image_data)

            # ── Step 3: Thumbnail generation ──────────────────────────
            thumbnail_path = self.thumbnail_service.generate_thumbnail(
                original_path, modified_timestamp
            )

            # ── Step 4: Update DB with thumbnail path ─────────────────
            if thumbnail_path:
                update_data = {
                    "original_path": original_path,
                    "thumbnail_path": thumbnail_path,
                }
                self.image_repository.upsert_image(update_data)

            return {
                "original_path": original_path,
                "thumbnail_path": thumbnail_path or "",
                "file_name": image_path.name,
                "skipped": False,
            }

        except PermissionError:
            logger.warning(f"Permission denied: '{image_path}'")
            return None
        except OSError as e:
            logger.warning(f"OS error processing '{image_path}': {e}")
            return None
        except Exception as e:
            logger.error(f"Unexpected error processing '{image_path}': {e}")
            return None

    def scan_folder(
        self,
        folder_path: str,
        on_image_ready: Optional[Callable] = None,
        on_progress: Optional[Callable] = None,
        is_cancelled: Optional[Callable] = None,
    ) -> int:
        """Full scan pipeline: discover → process → persist.
        
        Args:
            folder_path: Path to the folder to scan.
            on_image_ready: Callback(original_path, thumbnail_path, file_name)
            on_progress: Callback(current_index, total_count)
            is_cancelled: Callable returning True if scan should abort.
            
        Returns:
            Total number of successfully processed images.
        """
        # Create scan session
        session_id = self.image_repository.create_scan_session(folder_path)

        # Discover images
        image_paths = self.discover_images(folder_path)
        total = len(image_paths)

        if total == 0:
            self.image_repository.complete_scan_session(session_id, 0)
            logger.info("No images found in folder.")
            return 0

        # Report scan start to debug service
        if self._debug_service:
            self._debug_service.scan_started(folder_path, total, session_id)

        processed_count = 0

        for index, image_path in enumerate(image_paths):
            # Check cancellation before each image
            if is_cancelled and is_cancelled():
                logger.info(f"Scan cancelled after {processed_count} images.")
                self.image_repository.complete_scan_session(session_id, processed_count)
                return processed_count

            result = self.process_single_image(image_path, session_id)

            if result:
                processed_count += 1
                # Report to debug service
                if self._debug_service:
                    self._debug_service.scan_image_processed(skipped=result.get("skipped", False))
                if on_image_ready and result.get("thumbnail_path"):
                    on_image_ready(
                        result["original_path"],
                        result["thumbnail_path"],
                        result["file_name"],
                    )
            else:
                # Failed image
                if self._debug_service:
                    self._debug_service.scan_image_failed()

            if on_progress:
                on_progress(index + 1, total)

        # Complete session
        self.image_repository.complete_scan_session(session_id, processed_count)
        logger.info(f"Scan complete: {processed_count}/{total} images processed")
        return processed_count
