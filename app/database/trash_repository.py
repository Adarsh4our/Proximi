from typing import List, Tuple, Dict, Any, Optional
from sqlalchemy import func
from app.database.connection import db
from app.models.trash_record import TrashRecord
from app.utils.logger import logger
import datetime

class TrashRepository:
    """Handles persistence and querying of trash records."""

    def create_records(self, records_data: List[Dict[str, Any]]) -> List[TrashRecord]:
        """Bulk create trash records."""
        session = db.SessionLocal()
        created_records = []
        try:
            for data in records_data:
                record = TrashRecord(
                    original_path=data["original_path"],
                    trash_path=data["trash_path"],
                    group_id=data.get("group_id"),
                    scan_session_id=data["scan_session_id"],
                    image_id=data["image_id"],
                    batch_id=data["batch_id"]
                )
                session.add(record)
                created_records.append(record)
            
            session.commit()
            for record in created_records:
                session.refresh(record)
            return created_records
        except Exception as e:
            session.rollback()
            logger.error(f"Failed to create trash records: {e}")
            raise
        finally:
            session.close()

    def get_records_by_batch(self, batch_id: str) -> List[TrashRecord]:
        """Fetch all records belonging to a specific batch ID."""
        session = db.SessionLocal()
        try:
            return session.query(TrashRecord).filter(TrashRecord.batch_id == batch_id).all()
        finally:
            session.close()

    def mark_records_restored(self, record_ids: List[int]) -> None:
        """Mark a list of records as restored by setting restored_at timestamp."""
        session = db.SessionLocal()
        try:
            now = datetime.datetime.utcnow()
            session.query(TrashRecord)\
                .filter(TrashRecord.id.in_(record_ids))\
                .update({"restored_at": now}, synchronize_session=False)
            session.commit()
        except Exception as e:
            session.rollback()
            logger.error(f"Failed to mark records restored: {e}")
            raise
        finally:
            session.close()

    def get_trash_stats(self) -> Dict[str, int]:
        """Returns aggregate stats about the trash system."""
        session = db.SessionLocal()
        try:
            active_trash_count = session.query(func.count(TrashRecord.id))\
                .filter(TrashRecord.restored_at == None)\
                .scalar() or 0
                
            restored_count = session.query(func.count(TrashRecord.id))\
                .filter(TrashRecord.restored_at != None)\
                .scalar() or 0
                
            return {
                "active_count": active_trash_count,
                "restored_count": restored_count
            }
        except Exception as e:
            logger.error(f"Failed to get trash stats: {e}")
            return {"active_count": 0, "restored_count": 0}
        finally:
            session.close()
