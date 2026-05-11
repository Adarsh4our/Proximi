from PySide6.QtCore import QObject, Slot, Signal
from app.utils.logger import logger


class AppController(QObject):
    """Main QObject bridge for general application operations.
    
    Kept lightweight — only handles general app status.
    Scan operations are in ScanController.
    """

    statusTextChanged = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._status_text = "Ready"

    @Slot(result=str)
    def getStatusText(self):
        return self._status_text

    @Slot(str)
    def updateStatus(self, text: str):
        self._status_text = text
        self.statusTextChanged.emit(text)
        logger.debug(f"Status updated: {text}")
