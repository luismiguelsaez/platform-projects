from sqlalchemy import MetaData, Table, Column, Integer, String
from sqlalchemy_utils import database_exists, create_database

def init(engine):
  if not database_exists(engine.url):
    create_database(engine.url)

  metadata_obj = MetaData()

  ip = Table(
    'ip',
    metadata_obj,
    Column("id", Integer, primary_key=True),
    Column("address", String(15), nullable=False),
  )

  metadata_obj.create_all(engine)

  return ip
