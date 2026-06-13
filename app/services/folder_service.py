import os
from pathlib import Path
from app.utils.logger import logger


class FolderService:
    """Service to manage necessary application directories.

    Accepts an optional SettingsService reference. When session persistence
    is enabled, startup/exit cleanup is skipped so data survives restarts.
    """

    def __init__(self, settings_service=None):
        self.settings_service = settings_service
        self.base_dir = Path("data")
        self.required_dirs = [
            self.base_dir / "thumbnails",
            self.base_dir / "trash",
            self.base_dir / "cache",
            self.base_dir / "logs",
        ]



    def ensure_data_directories(self) -> None:
        """Creates required application directories if they don't exist."""
        for directory in self.required_dirs:
            try:
                directory.mkdir(parents=True, exist_ok=True)
                logger.debug(f"Ensured directory exists: {directory}")
            except Exception as e:
                logger.error(f"Failed to create directory {directory}: {e}")

    def cleanup_startup(self) -> None:
        """Cleans up data directories on startup."""
        import shutil
        logger.info("Performing startup cleanup...")
        for directory in self.required_dirs:
            if directory.name == "logs":
                continue  # Skip logs — may be locked by the running logger
            shutil.rmtree(directory, ignore_errors=True)

        # Remove database
        db_file = self.base_dir / "proximi.db"
        if db_file.exists():
            try:
                db_file.unlink()
            except Exception as e:
                logger.error(f"Failed to delete db file on startup: {e}")

        # Clean up faces dir (not in required_dirs but created by face service)
        faces_dir = self.base_dir / "faces"
        shutil.rmtree(faces_dir, ignore_errors=True)

    def cleanup_data_directory(self) -> None:
        """Deletes the entire data directory on app exit.

        Skipped when session persistence is enabled — only closes DB handles
        gracefully so data is available on next launch.
        """
        from app.database.connection import db
        from app.utils.logger import shutdown_logger

        if self._persistence_enabled:
            logger.info(
                "Session persistence is ON — retaining session data on exit."
            )
            db.close_database()
            shutdown_logger()
            return

        import shutil
        logger.info("Initiating session data cleanup (persistence OFF)...")
        db.close_database()
        shutdown_logger()

        try:
            shutil.rmtree(self.base_dir, ignore_errors=True)
            print(f"Cleaned up {self.base_dir} directory.")
        except Exception as e:
            print(f"Failed to clean up {self.base_dir}: {e}")
