from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
import os
from dotenv import load_dotenv
# load environment variables first
load_dotenv()

# Database URL
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./database.db")

# Create engine
engine = create_engine(
    DATABASE_URL, connect_args={"check_same_thread": False}  # Needed for SQLite in multithreaded apps like FastAPI
)

# SessionLocal will be used for DB sessions
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base class for ORM models
Base = declarative_base()

def initialize_database():
    """
    Create the database tables if they do not exist.
    This should be called at the start of the application.
    """
    Base.metadata.create_all(bind=engine)