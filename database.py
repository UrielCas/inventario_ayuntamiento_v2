from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

# Estas son las credenciales exactas de tu docker-compose.yml
URL_BASE_DATOS = "postgresql://admin_tics:password123@localhost:5432/helpdesk_inventario"

# Creamos el "motor" que se enchufa a PostgreSQL
engine = create_engine(URL_BASE_DATOS)

# Creamos la sesión para poder hacer consultas
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base para crear nuestros modelos (las tablas)
Base = declarative_base()