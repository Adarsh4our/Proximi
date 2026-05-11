import os
from pathlib import Path
from sqlalchemy import create_engine
from sqlalchemy.orm import scoped_session, sessionmaker
from app.utils.logger import logger
from app.database.base import Base
# Import models here so Base metadata is populated
import app.models

class DatabaseConnection:
    def __init__(self):
        self.db_path = Path("data/proximi.db")
        self.engine = None
        self.SessionLocal = None

    def initialize_database(self):
        """Creates the engine, session factory, and initializes the schema."""
        try:
            # Ensure parent directory exists
            self.db_path.parent.mkdir(parents=True, exist_ok=True)
            
            # SQLite connection string
            sqlite_url = f"sqlite:///{self.db_path}"
            
            # Create engine
            self.engine = create_engine(
                sqlite_url, 
                connect_args={"check_same_thread": False},
                echo=False # Set to True for SQL logging
            )
            
            # Create session factory
            session_factory = sessionmaker(autocommit=False, autoflush=False, bind=self.engine)
            self.SessionLocal = scoped_session(session_factory)
            
            # Create tables based on imported models
            Base.metadata.create_all(bind=self.engine)
            
            logger.info("Database initialized successfully.")
        except Exception as e:
            logger.error(f"Failed to initialize database: {e}")

db = DatabaseConnection()
