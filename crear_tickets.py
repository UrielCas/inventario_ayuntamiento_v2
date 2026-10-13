# Autor: URIEL GUTIÉRREZ CASTILLO
from database import engine, Base
from models import Ticket # Asegúrate de que 'models' coincida con el nombre de tu archivo de modelos

def crear_tabla_tickets():
    # Esto creará solo las tablas que falten (en este caso, 'tickets')
    Base.metadata.create_all(bind=engine)
    print("¡Tabla de Tickets creada exitosamente en PostgreSQL!")

if __name__ == "__main__":
    crear_tabla_tickets()