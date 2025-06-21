from sqlalchemy import Column, Integer, String, JSON
from utils.sql_utils import Base

class LiveMatch(Base):
    __tablename__ = 'live_matches'

    id = Column(Integer, primary_key=True, index=True)
    match_code = Column(String, unique=True, index=True)
    match_data = Column(JSON, nullable=False)