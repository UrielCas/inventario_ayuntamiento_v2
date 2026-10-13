# Autor: URIEL GUTIÉRREZ CASTILLO
from database import SessionLocal
from models import Usuario
from passlib.context import CryptContext

# Configuramos el encriptador de contraseñas
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def crear_usuarios_prueba():
    db = SessionLocal()
    
    # 1. Definimos nuestros 3 usuarios con contraseña fácil ("123")
    usuarios = [
        Usuario(nombre_completo="Uriel Admin", correo="admin@ayto.com", password_hash=pwd_context.hash("123"), rol="admin"),
        Usuario(nombre_completo="Carlos Técnico", correo="tecnico@ayto.com", password_hash=pwd_context.hash("123"), rol="tecnico"),
        Usuario(nombre_completo="Ana Recolector", correo="recolector@ayto.com", password_hash=pwd_context.hash("123"), rol="recolector")
    ]
    
    # 2. Los inyectamos a la base de datos (verificando que no existan ya)
    for u in usuarios:
        existe = db.query(Usuario).filter(Usuario.correo == u.correo).first()
        if not existe:
            db.add(u)
            
    db.commit()
    db.close()
    print("✅ ¡Usuarios inyectados! Correos: admin@ayto.com, tecnico@ayto.com, recolector@ayto.com (Pass: 123)")

if __name__ == "__main__":
    crear_usuarios_prueba()