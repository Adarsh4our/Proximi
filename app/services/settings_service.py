from app.utils.logger import logger

class SettingsService:
    """Service to manage application settings."""
    
    def __init__(self):
        self._settings = {
            "theme": "dark",
            "scan_preferences": {},
            "cache_preferences": {}
        }
        logger.debug("SettingsService initialized")

    def get_setting(self, key: str, default=None):
        return self._settings.get(key, default)

    def set_setting(self, key: str, value):
        self._settings[key] = value
        logger.debug(f"Setting updated: {key} = {value}")
