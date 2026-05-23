import time
from pathlib import Path
from PIL import Image as PILImage
import imagehash
from typing import Callable
from concurrent.futures import ThreadPoolExecutor, as_completed

from app.database.image_repository import ImageRepository
from app.utils.logger import logger
from app.services.debug_service import DebugService

# Number of parallel threads for hash computation.
# imagehash operations release the GIL during numpy work, so threading helps.
_HASH_WORKERS = 4


class HashService:
    """Computes and persists perceptual hashes for images.

    Uses a ThreadPoolExecutor to parallelise hash computation across
    multiple images simultaneously — typically 3-4x faster than serial.
    """

    def __init__(self, image_repository: ImageRepository, debug_service: DebugService = None):
        self._image_repository = image_repository
        self._debug_service = debug_service

    def _compute_hashes_for_image(self, img) -> tuple[int, str, str] | tuple[int, None, None]:
        """Compute pHash + dHash for a single image. Thread-safe.

        Returns:
            (image_id, phash_str, dhash_str) on success,
            (image_id, None, None) on failure.
        """
        try:
            # Prefer thumbnail (already small) over original for speed
            source_path = (
                img.thumbnail_path
                if img.thumbnail_path and Path(img.thumbnail_path).exists()
                else img.original_path
            )

            with PILImage.open(source_path) as pil_img:
                if pil_img.mode != "RGB":
                    pil_img = pil_img.convert("RGB")
                phash = str(imagehash.phash(pil_img))
                dhash = str(imagehash.dhash(pil_img))

            return img.id, phash, dhash

        except Exception as e:
            logger.error(
                f"Failed to compute hash for image {img.id} ({img.original_path}): {e}"
            )
            return img.id, None, None

    def compute_hashes_for_all(
        self,
        on_progress: Callable[[int, int], None] = None,
        is_cancelled: Callable[[], bool] = None,
    ) -> int:
        """Process all unhashed images in parallel. Returns count processed."""
        images_to_hash = self._image_repository.get_images_without_hashes()
        total = len(images_to_hash)

        if total == 0:
            logger.info("No unhashed images found. Skipping hash computation.")
            return 0

        logger.info(f"Computing hashes for {total} images ({_HASH_WORKERS} workers)...")
        processed = 0

        with ThreadPoolExecutor(max_workers=_HASH_WORKERS) as executor:
            future_to_img = {
                executor.submit(self._compute_hashes_for_image, img): img
                for img in images_to_hash
            }

            for future in as_completed(future_to_img):
                if is_cancelled and is_cancelled():
                    executor.shutdown(wait=False, cancel_futures=True)
                    break

                image_id, phash, dhash = future.result()

                if phash is not None:
                    self._image_repository.update_hashes(image_id, phash, dhash)
                    processed += 1

                    if self._debug_service:
                        self._debug_service.similarity_hash_computed()

                if on_progress:
                    on_progress(processed, total)

        logger.info(f"Hash computation complete: {processed}/{total} images hashed.")
        return processed
