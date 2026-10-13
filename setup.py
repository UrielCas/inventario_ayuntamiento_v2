from database import SessionLocal
import models
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
db = SessionLocal()

# 1. Crear tu usuario Administrador
admin = models.Usuario(
    nombre_completo="URIEL GUTIÉRREZ CASTILLO",
    correo="uriel@ayuntamiento.gob.mx",
    password_hash=pwd_context.hash("password_super_seguro123"),
    rol="admin"
)
db.add(admin)

# 2. Crear un equipo de prueba
equipo = models.Equipo(
    folio_inventario="AYTO-TIC-001",
    departamento="Tesorería",
    ip="192.168.1.15",
    caracteristicas="PC de Escritorio KMEX"
)
db.add(equipo)

db.commit()
print("¡Usuario Admin y Equipo de prueba creados con éxito!")


