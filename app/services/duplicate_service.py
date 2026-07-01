import imagehash
from PIL import Image as PILImage
from pathlib import Path
from typing import Callable, Tuple, Optional

from app.database.image_repository import ImageRepository
from app.services.trash_service import TrashService
from app.utils.logger import logger

# Maximum hamming distance between two 64-bit pHashes to consider images "the same
# content at different quality levels".
#   0-2  bits differ → same scene, different JPEG quality / slight compression
#   3-10 bits differ → noticeably different (crop, filter, color grade)
# A distance of 2 maps to ~96.9 % bit-similarity (≥ 98 % of the 64-bit signal agrees).
PHASH_NEAR_DUPLICATE_THRESHOLD = 2


class DuplicateService:
    def __init__(self, image_repository: ImageRepository, trash_service: TrashService):
        self.image_repository = image_repository
        self.trash_service = trash_service

    def remove_exact_duplicates(
        self,
        on_progress: Callable[[int, int], None] = None,
        is_cancelled: Callable[[], bool] = None,
    ) -> list[str]:
        """
        Finds near-duplicate images (≥ 98 % perceptually similar) and stages the
        lower-quality copies for deletion.

        'Higher quality' is defined as:
          1. Larger total pixel count  (width × height)
          2. Larger file size as a tie-breaker

        Near-duplicate groups are built using a Union-Find over pHash hamming distance
        so that similarity is applied transitively (A≈B and B≈C → A,B,C all grouped).

        Returns the list of original_paths that were staged for removal.
        """
        # ── 1. Fetch all images ───────────────────────────────────────────
        images = self.image_repository.get_all_images()
        if not images:
            return []

        total_images = len(images)

        # ── 2. Ensure every image has a pHash ────────────────────────────
        logger.info(
            f"Computing hashes for {total_images} images for near-duplicate detection..."
        )
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
                on_progress(int((i / total_images) * 40), 100)  # Stage 1 → 40 %

        # Keep only images that have a valid hash
        hashed_images = [img for img in images if img.phash]

        # ── 3. Convert hex-strings back to ImageHash objects ─────────────
        hash_objects: list[imagehash.ImageHash] = []
        valid_images = []
        for img in hashed_images:
            try:
                hash_objects.append(imagehash.hex_to_hash(img.phash))
                valid_images.append(img)
            except Exception as e:
                logger.warning(f"Could not parse pHash for image {img.id}: {e}")

        n = len(valid_images)
        logger.info(f"Running near-duplicate clustering on {n} images...")

        # ── 4. Union-Find grouping ────────────────────────────────────────
        parent = list(range(n))

        def find(x: int) -> int:
            while parent[x] != x:
                parent[x] = parent[parent[x]]  # path compression
                x = parent[x]
            return x

        def union(a: int, b: int) -> None:
            parent[find(a)] = find(b)

        # O(n²) comparison — acceptable for typical library sizes (< 50 k images)
        for i in range(n):
            if is_cancelled and is_cancelled():
                return []

            for j in range(i + 1, n):
                dist = hash_objects[i] - hash_objects[j]
                if dist <= PHASH_NEAR_DUPLICATE_THRESHOLD:
                    union(i, j)

            if on_progress and i % max(1, n // 20) == 0:
                progress_pct = 40 + int((i / max(1, n)) * 50)
                on_progress(progress_pct, 100)

        # ── 5. Collect groups ─────────────────────────────────────────────
        from collections import defaultdict

        groups: dict[int, list] = defaultdict(list)
        for idx, img in enumerate(valid_images):
            groups[find(idx)].append(img)

        dup_groups = [g for g in groups.values() if len(g) > 1]
        logger.info(
            f"Found {len(dup_groups)} near-duplicate group(s) across "
            f"{sum(len(g) for g in dup_groups)} images."
        )

        # ── 6. Pick the keeper (highest resolution, then file size) ───────
        ids_to_stage: list[int] = []
        removed_paths: list[str] = []

        for group in dup_groups:
            if is_cancelled and is_cancelled():
                break

            group.sort(
                key=lambda img: (
                    (img.width or 0) * (img.height or 0),  # pixel count ↓
                    img.file_size or 0,                     # file size ↓
                ),
                reverse=True,
            )

            keeper = group[0]
            duplicates = group[1:]

            logger.debug(
                f"Keeper: {keeper.file_name} "
                f"({keeper.width}×{keeper.height}, {keeper.file_size} bytes) | "
                f"Staging {len(duplicates)} lower-quality copy/copies."
            )

            for dup in duplicates:
                ids_to_stage.append(dup.id)
                removed_paths.append(dup.original_path)

        # ── 7. Stage for trash ────────────────────────────────────────────
        if ids_to_stage:
            self.image_repository.stage_images_for_trash(ids_to_stage)
            logger.info(
                f"Staged {len(ids_to_stage)} near-duplicate(s) for deletion "
                f"(kept highest-resolution copy in each group)."
            )

        if on_progress:
            on_progress(100, 100)

        return removed_paths

    # ── Helpers ───────────────────────────────────────────────────────────

    def _compute_hashes(self, img) -> Tuple[Optional[str], Optional[str]]:
        """Compute pHash + dHash for an image, preferring the thumbnail path."""
        path = (
            img.thumbnail_path
            if img.thumbnail_path and Path(img.thumbnail_path).exists()
            else img.original_path
        )
        try:
            with PILImage.open(path) as pil_img:
                pil_img = pil_img.convert("RGB")
                ph = str(imagehash.phash(pil_img))
                dh = str(imagehash.dhash(pil_img))
                return ph, dh
        except Exception as e:
            logger.error(f"Failed to hash {path}: {e}")
            return None, None
