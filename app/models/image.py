from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database.base import Base


class Image(Base):
    """Represents a single image file discovered during scanning."""
    __tablename__ = "images"

    id = Column(Integer, primary_key=True, autoincrement=True)
    original_path = Column(String, unique=True, nullable=False, index=True)
    file_name = Column(String, nullable=False)
    extension = Column(String, nullable=False)
    width = Column(Integer, nullable=True)
    height = Column(Integer, nullable=True)
    file_size = Column(Integer, nullable=False)
    created_at = Column(DateTime, default=func.now())
    modified_at = Column(DateTime, nullable=False)  # file's mtime from filesystem
    thumbnail_path = Column(String, nullable=True)
    scan_session_id = Column(Integer, ForeignKey("scan_sessions.id"))

    # Relationship back to scan session
    scan_session = relationship("ScanSession", back_populates="images")

    def __repr__(self) -> str:
        return f"<Image(id={self.id}, name='{self.file_name}')>"
