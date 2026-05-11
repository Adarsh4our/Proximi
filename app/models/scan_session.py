from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database.base import Base


class ScanSession(Base):
    """Represents a single folder scan operation."""
    __tablename__ = "scan_sessions"

    id = Column(Integer, primary_key=True, autoincrement=True)
    folder_path = Column(String, nullable=False)
    started_at = Column(DateTime, default=func.now())
    completed_at = Column(DateTime, nullable=True)
    images_found = Column(Integer, default=0)
    status = Column(String, default="in_progress")  # in_progress | completed | failed

    # Relationship to images discovered in this session
    images = relationship("Image", back_populates="scan_session")

    def __repr__(self) -> str:
        return f"<ScanSession(id={self.id}, folder='{self.folder_path}', status='{self.status}')>"
