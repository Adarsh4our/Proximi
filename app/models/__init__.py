# Models package — SQLAlchemy ORM models
# All models must be imported here so Base.metadata.create_all() discovers them.
from .image import Image
from .scan_session import ScanSession
