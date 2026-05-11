from PySide6.QtCore import QObject, Slot, Signal
from app.utils.logger import logger

class SettingsController(QObject):
    """QObject bridge for settings operations."""
    
    themeChanged = Signal(str)
    
    def __init__(self, settings_service, parent=None):
        super().__init__(parent)
        self.settings_service = settings_service

    @Slot(result=str)
    def getTheme(self):
        return self.settings_service.get_setting("theme", "dark")
        
    @Slot(str)
    def setTheme(self, theme_name):
        self.settings_service.set_setting("theme", theme_name)
        self.themeChanged.emit(theme_name)
