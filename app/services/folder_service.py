import os
from pathlib import Path
from app.utils.logger import logger

class FolderService:
    """Service to manage necessary application directories."""
    
    def __init__(self):
        self.base_dir = Path("data")
        self.required_dirs = [
            self.base_dir / "thumbnails",
            self.base_dir / "trash",
            self.base_dir / "cache",
            self.base_dir / "logs"
        ]

    def ensure_data_directories(self) -> None:
        """Creates required application directories if they don't exist."""
        for directory in self.required_dirs:
            try:
                directory.mkdir(parents=True, exist_ok=True)
                logger.debug(f"Ensured directory exists: {directory}")
            except Exception as e:
                logger.error(f"Failed to create directory {directory}: {e}")
