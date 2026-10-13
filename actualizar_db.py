from database import engine
from sqlalchemy import text

with engine.begin() as conn:
    try:
        # Agregamos las columnas faltantes a la tabla tickets
        conn.execute(text("ALTER TABLE tickets ADD COLUMN recolector_id INTEGER;"))
        conn.execute(text("ALTER TABLE tickets ADD COLUMN tecnico_id INTEGER;"))
        
        # Agregamos las relaciones (Foreign Keys) para que se conecten con la tabla de usuarios
        conn.execute(text("ALTER TABLE tickets ADD CONSTRAINT fk_recolector FOREIGN KEY (recolector_id) REFERENCES usuarios (id);"))
        conn.execute(text("ALTER TABLE tickets ADD CONSTRAINT fk_tecnico FOREIGN KEY (tecnico_id) REFERENCES usuarios (id);"))
        
        print("¡Las columnas recolector_id y tecnico_id se agregaron con éxito a tu tabla tickets!")
    except Exception as e:
        print(f"Ocurrió un detalle: {e}")