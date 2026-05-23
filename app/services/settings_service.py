import json
from pathlib import Path
import platformdirs
from app.utils.logger import logger


class SettingsService:
    """Persistent settings service backed by a JSON config file.

    Config is stored in the OS-appropriate user config directory:
      Windows : %APPDATA%\\Proximi\\settings.json
      macOS   : ~/Library/Application Support/Proximi/settings.json
      Linux   : ~/.config/Proximi/settings.json
    """

    DEFAULTS: dict = {
        # ── General ────────────────────────────────────────────────────
        "theme": "dark",
        "thumbnail_quality": 85,
        "scan_extensions": [".jpg", ".jpeg", ".png", ".webp", ".heic", ".bmp", ".tiff"],

        # ── Similarity Thresholds ──────────────────────────────────────
        "similarity": {
            "phash_threshold": 12,
            "ssim_threshold": 0.55,
            "dhash_threshold": 18,
            "histogram_threshold": 0.30,
        },

        # ── Session ────────────────────────────────────────────────────
        "session_persistence": False,

        # ── Onboarding ─────────────────────────────────────────────────
        "onboarding_completed": False,
    }

    def __init__(self):
        self._config_dir = Path(platformdirs.user_config_dir("Proximi", "Proximi"))
        self._config_file = self._config_dir / "settings.json"
        self._settings = self._load()
        logger.debug(f"SettingsService initialized — config at {self._config_file}")

    # ── Load / Save ────────────────────────────────────────────────────

    def _load(self) -> dict:
        """Load settings from disk, merging with defaults for forward-compat."""
        if self._config_file.exists():
            try:
                with open(self._config_file, "r", encoding="utf-8") as f:
                    saved = json.load(f)
                # Deep-merge: top-level keys + nested 'similarity' dict
                merged = dict(self.DEFAULTS)
                merged.update(saved)
                # Ensure nested similarity dict is also merged
                if "similarity" in saved:
                    merged["similarity"] = {**self.DEFAULTS["similarity"], **saved["similarity"]}
                logger.debug("Settings loaded from disk.")
                return merged
            except Exception as e:
                logger.warning(f"Failed to load settings, using defaults: {e}")
        return dict(self.DEFAULTS)

    def save(self):
        """Persist current settings to disk."""
        try:
            self._config_dir.mkdir(parents=True, exist_ok=True)
            with open(self._config_file, "w", encoding="utf-8") as f:
                json.dump(self._settings, f, indent=2)
            logger.debug("Settings saved.")
        except Exception as e:
            logger.error(f"Failed to save settings: {e}")

    # ── Public API ─────────────────────────────────────────────────────

    def get(self, key: str, default=None):
        """Get a top-level setting value."""
        return self._settings.get(key, default)

    def set(self, key: str, value):
        """Set a top-level setting and auto-save."""
        self._settings[key] = value
        self.save()
        logger.debug(f"Setting updated: {key} = {value}")

    def get_similarity(self, key: str, default=None):
        """Get a value from the nested similarity thresholds dict."""
        return self._settings.get("similarity", {}).get(key, default)

    def set_similarity(self, key: str, value):
        """Update a nested similarity threshold value and auto-save."""
        if "similarity" not in self._settings:
            self._settings["similarity"] = dict(self.DEFAULTS["similarity"])
        self._settings["similarity"][key] = value
        self.save()
        logger.debug(f"Similarity setting updated: {key} = {value}")

    def reset_to_defaults(self):
        """Reset ALL settings to factory defaults and save."""
        self._settings = dict(self.DEFAULTS)
        self._settings["similarity"] = dict(self.DEFAULTS["similarity"])
        self.save()
        logger.info("Settings reset to defaults.")

    def reset_similarity_to_defaults(self):
        """Reset only similarity thresholds to defaults and save."""
        self._settings["similarity"] = dict(self.DEFAULTS["similarity"])
        self.save()
        logger.info("Similarity thresholds reset to defaults.")

    # ── Legacy compat ──────────────────────────────────────────────────

    def get_setting(self, key: str, default=None):
        return self.get(key, default)

    def set_setting(self, key: str, value):
        self.set(key, value)
