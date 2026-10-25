from database import engine
from sqlalchemy import text

with engine.connect() as conn:
    conn.execute(text("ALTER TABLE equipos ADD COLUMN ruta_foto VARCHAR;"))
    conn.commit()
    print("¡Columna ruta_foto agregada con éxito!")
    