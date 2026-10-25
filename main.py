# Autor: URIEL GUTIÉRREZ CASTILLO
# Proyecto: Helpdesk y Control de Inventario - H. Ayuntamiento

from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from passlib.context import CryptContext
from typing import Optional
from jose import JWTError, jwt

import shutil
from fastapi import File, UploadFile, Form


from database import engine, Base, SessionLocal
import models
import schemas



import os
from fastapi.staticfiles import StaticFiles

# Esto obliga a Python a crear la carpeta automáticamente si se te olvida
os.makedirs("fotos_equipos", exist_ok=True)

Base.metadata.create_all(bind=engine)

# 1. PRIMERO creamos la aplicación
app = FastAPI(
    title="API Helpdesk Ayuntamiento",
    description="Sistema de gestión de inventario, tickets y usuarios",
    version="1.0.0"
)

# 2. DESPUÉS montamos la carpeta usando la variable "app" que ya existe
app.mount("/fotos", StaticFiles(directory="fotos_equipos"), name="fotos")


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

SECRET_KEY = "ayuntamiento_secreto_super_seguro" 
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

def verificar_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def obtener_password_hash(password):
    return pwd_context.hash(password)

def crear_token_acceso(data: dict, expires_delta: timedelta | None = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()




# --- NUEVO: EL "CADENERO" CON DETECTOR DE ERRORES ---
def obtener_usuario_actual(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    print(f"\n--- REVISIÓN DE SEGURIDAD ---")
    print(f"Token recibido: {token[:20]}... (truncado)")
    
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        correo: str = payload.get("sub")
        print(f"Correo en el token: {correo}")
        
        if correo is None:
            print("Fallo: No se encontró correo en el token")
            raise HTTPException(status_code=401, detail="Token sin correo")
            
        token_data = schemas.TokenData(correo=correo)
        
    except JWTError as e:
        print(f"Fallo de encriptación: {e}")
        raise HTTPException(status_code=401, detail="Token inválido")
    
    usuario = db.query(models.Usuario).filter(models.Usuario.correo == token_data.correo).first()
    if usuario is None:
        print(f"Fallo: El correo '{token_data.correo}' no existe en la base de datos")
        raise HTTPException(status_code=401, detail="Usuario fantasma")
    
    print(f"Acceso permitido para: {usuario.nombre_completo}")
    print(f"-----------------------------\n")
    return usuario












# ==========================================
# RUTAS PÚBLICAS (No piden token)
# ==========================================
@app.post("/usuarios/", response_model=schemas.UsuarioResponse)
def crear_usuario(usuario: schemas.UsuarioCreate, db: Session = Depends(get_db)):
    usuario_existente = db.query(models.Usuario).filter(models.Usuario.correo == usuario.correo).first()
    if usuario_existente:
        raise HTTPException(status_code=400, detail="El correo ya está registrado")
    
    hashed_password = obtener_password_hash(usuario.password)
    nuevo_usuario = models.Usuario(
        nombre_completo=usuario.nombre_completo,
        correo=usuario.correo,
        password_hash=hashed_password,
        rol=usuario.rol
    )
    db.add(nuevo_usuario)
    db.commit()
    db.refresh(nuevo_usuario)
    return nuevo_usuario












@app.post("/token")
def login_para_obtener_token(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    usuario = db.query(models.Usuario).filter(models.Usuario.correo == form_data.username).first()
    if not usuario or not verificar_password(form_data.password, usuario.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Correo o contraseña incorrectos",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = crear_token_acceso(
        data={"sub": usuario.correo}, expires_delta=access_token_expires
    )
    
    # NUEVO: Devolvemos también el rol y el nombre para que Flutter sepa a qué pantalla enviarlo
    return {
        "access_token": access_token, 
        "token_type": "bearer",
        "rol": usuario.rol,
        "nombre": usuario.nombre_completo
    }

@app.get("/")
def ruta_principal():
    return {"mensaje": "¡El cerebro del Helpdesk está vivo y asegurado!"}






# ==========================================
# RUTAS PROTEGIDAS (AQUÍ EXIGIMOS EL TOKEN)
# ==========================================


@app.post("/equipos/", response_model=schemas.EquipoResponse)
def registrar_equipo(
    folio_inventario: str = Form(...),
    departamento: str = Form(...),
    ip: str = Form(...),
    caracteristicas: str = Form(...),
    tipo_equipo: str = Form(...),
    marca: str = Form(...),
    modelo: str = Form(...),
    foto: Optional[UploadFile] = File(None), # <--- Sintaxis a prueba de fallos
    db: Session = Depends(get_db), 
    usuario_actual: models.Usuario = Depends(obtener_usuario_actual)
):
    ruta_imagen = None
    
    if foto and foto.filename:
        extension = foto.filename.split(".")[-1]
        nombre_archivo = f"{folio_inventario}.{extension}"
        ruta_completa = f"fotos_equipos/{nombre_archivo}"
        
        with open(ruta_completa, "wb") as buffer:
            shutil.copyfileobj(foto.file, buffer)
        
        ruta_imagen = f"/fotos/{nombre_archivo}"

    nuevo_equipo = models.Equipo(
        folio_inventario=folio_inventario,
        departamento=departamento,
        ip=ip,
        caracteristicas=caracteristicas,
        tipo_equipo=tipo_equipo,
        marca=marca,
        modelo=modelo,
        ruta_foto=ruta_imagen
    )
    
    db.add(nuevo_equipo)
    db.commit()
    db.refresh(nuevo_equipo)
    return nuevo_equipo








@app.get("/equipos/{equipo_id}", response_model=schemas.EquipoResponse)
def obtener_equipo(equipo_id: int, db: Session = Depends(get_db), usuario_actual: models.Usuario = Depends(obtener_usuario_actual)):
    equipo = db.query(models.Equipo).filter(models.Equipo.id == equipo_id).first()
    if not equipo:
        raise HTTPException(status_code=404, detail="Equipo no encontrado")
    return equipo













@app.post("/tickets/", response_model=schemas.Ticket)
def crear_ticket(ticket: schemas.TicketCreate, db: Session = Depends(get_db), usuario_actual: models.Usuario = Depends(obtener_usuario_actual)):
    
    # 1. Verificamos que el equipo exista en el inventario
    equipo = db.query(models.Equipo).filter(models.Equipo.id == ticket.equipo_id).first()
    if not equipo:
        raise HTTPException(status_code=404, detail="Equipo no encontrado")
        
    # === EL NUEVO CANDADO ANTI-DUPLICADOS ===
    # Buscamos si el equipo ya tiene un ticket que NO esté Resuelto/Entregado
    ticket_activo = db.query(models.Ticket).filter(
        models.Ticket.equipo_id == ticket.equipo_id,
        models.Ticket.estatus.notin_(["Resuelto", "Entregado"]) # Ajusta estas palabras según los estados que uses
    ).first()
    
    if ticket_activo:
        raise HTTPException(
            status_code=400, 
            detail=f"Este equipo ya está en el taller (Ticket #{ticket_activo.id} en estado: {ticket_activo.estatus})"
        )
    # ==========================================

    # 2. Creamos el ticket dejando huella de quién lo recibió en el sistema
    nuevo_ticket = models.Ticket(
        equipo_id=ticket.equipo_id,
        recolector_id=usuario_actual.id,
        nombre_entrega=ticket.nombre_entrega,
        nombre_recibe=usuario_actual.nombre_completo,
        telefono=ticket.telefono,
        departamento=ticket.departamento,
        diagnostico_inicial=ticket.diagnostico_inicial,
        accesorios=ticket.accesorios,
        estado_fisico=ticket.estado_fisico,
        estatus="Recibido" # El estado oficial para el inicio
    )
    
    db.add(nuevo_ticket)
    db.commit()
    db.refresh(nuevo_ticket)
    return nuevo_ticket













@app.get("/equipos/{equipo_id}/tickets", response_model=list[schemas.TicketResponse])
def obtener_tickets_de_equipo(equipo_id: int, db: Session = Depends(get_db), usuario_actual: models.Usuario = Depends(obtener_usuario_actual)):
    tickets = db.query(models.Ticket).filter(models.Ticket.equipo_id == equipo_id).all()
    return tickets






from pydantic import BaseModel

# Creamos un esquema rápido para recibir el nombre del técnico
class AsignacionTecnico(BaseModel):
    nombre_tecnico: str

@app.put("/tickets/{ticket_id}/asignar")
def asignar_tecnico(ticket_id: int, asignacion: AsignacionTecnico, db: Session = Depends(get_db), usuario_actual: models.Usuario = Depends(obtener_usuario_actual)):
    
    # 1. Buscamos el ticket en la base de datos
    ticket = db.query(models.Ticket).filter(models.Ticket.id == ticket_id).first()
    
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket no encontrado")
        
    # 2. Actualizamos los datos
    ticket.tecnico_asignado = asignacion.nombre_tecnico
    ticket.estatus = "En Reparación" # Esto mueve el ticket a la siguiente fase
    
    # 3. Guardamos los cambios
    db.commit()
    db.refresh(ticket)
    
    return {"mensaje": "Asignación exitosa", "ticket_id": ticket.id, "tecnico": ticket.tecnico_asignado}







@app.put("/tickets/{ticket_id}", response_model=schemas.TicketResponse)
def actualizar_ticket(ticket_id: int, ticket_actualizado: schemas.TicketUpdate, db: Session = Depends(get_db), usuario_actual: models.Usuario = Depends(obtener_usuario_actual)):
    ticket = db.query(models.Ticket).filter(models.Ticket.id == ticket_id).first()
    if not ticket:
        raise HTTPException(status_code=404, detail="El ticket indicado no existe")
    
    # 1. Actualizamos el estatus (ej. "Asignado")
    if ticket_actualizado.estatus is not None:
        ticket.estatus = ticket_actualizado.estatus
        
    # 2. CORRECCIÓN: Guardamos el ID en ambas variables para que Flutter lo encuentre
    if ticket_actualizado.tecnico_asignado is not None:
        ticket.tecnico_id = int(ticket_actualizado.tecnico_asignado)
        ticket.tecnico_asignado = str(ticket_actualizado.tecnico_asignado) # <--- LA LÍNEA MÁGICA 🪄
        
    # 3. Datos para cuando el técnico repare el equipo
    if ticket_actualizado.ejecucion_servicio is not None:
        ticket.ejecucion_servicio = ticket_actualizado.ejecucion_servicio
    if ticket_actualizado.requerimiento_refaccion is not None:
        ticket.requerimiento_refaccion = ticket_actualizado.requerimiento_refaccion
        
    db.commit()
    db.refresh(ticket)
    return ticket






@app.get("/equipos/buscar/{folio}", response_model=schemas.EquipoResponse)
def buscar_equipo_por_folio(folio: str, db: Session = Depends(get_db), usuario_actual: models.Usuario = Depends(obtener_usuario_actual)):
    equipo = db.query(models.Equipo).filter(models.Equipo.folio_inventario == folio).first()
    
    if not equipo:
        raise HTTPException(status_code=404, detail="Equipo no encontrado")
    
    return equipo



# ==========================================
# RUTAS PARA EL PANEL DEL ADMINISTRADOR
# ==========================================        

@app.get("/tickets/todos", response_model=list[schemas.TicketResponse])
def obtener_todos_los_tickets(db: Session = Depends(get_db), usuario_actual: models.Usuario = Depends(obtener_usuario_actual)):
    # Traemos todos los tickets ordenados del más reciente al más viejo
    tickets = db.query(models.Ticket).order_by(models.Ticket.id.desc()).all()
    return tickets

@app.get("/usuarios/tecnicos")
def obtener_tecnicos(db: Session = Depends(get_db), usuario_actual: models.Usuario = Depends(obtener_usuario_actual)):
    # Buscamos solo a los usuarios que tengan el rol de "tecnico"
    tecnicos = db.query(models.Usuario).filter(models.Usuario.rol == "tecnico").all()
    
    # Devolvemos solo su ID y su nombre para llenar el menú desplegable en Flutter
    return [{"id": t.id, "nombre": t.nombre_completo} for t in tecnicos]



# ==========================================
# RUTAS PARA EL TALLER DEL TÉCNICO
# ==========================================

@app.get("/tickets/mis-asignaciones", response_model=list[schemas.TicketResponse])
def obtener_mis_tickets(db: Session = Depends(get_db), usuario_actual: models.Usuario = Depends(obtener_usuario_actual)):
    # Traemos solo los tickets donde tecnico_id coincida con el ID de Carlos (el usuario actual)
    tickets = db.query(models.Ticket).filter(models.Ticket.tecnico_id == usuario_actual.id).order_by(models.Ticket.id.desc()).all()
    return tickets



# --- NUEVO: RENOMBRAR USUARIO ---
@app.put("/usuarios/renombrar/{usuario_id}")
def renombrar_usuario(usuario_id: int, nuevo_nombre: str, nuevo_correo: str, db: Session = Depends(get_db)):
    usuario = db.query(models.Usuario).filter(models.Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    usuario.nombre_completo = nuevo_nombre
    usuario.correo = nuevo_correo
    db.commit()
    return {"mensaje": f"Usuario actualizado a: {usuario.nombre_completo}"}

# --- NUEVO: ELIMINAR POR COMPLETO (HARD DELETE) ---
@app.delete("/usuarios/eliminar_fisico/{usuario_id}")
def eliminar_usuario_fisico(usuario_id: int, db: Session = Depends(get_db)):
    usuario = db.query(models.Usuario).filter(models.Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    db.delete(usuario) # Esto lo borra de la base de datos para siempre
    db.commit()
    return {"mensaje": "Usuario eliminado permanentemente"}



@app.get("/estadisticas/")
def obtener_estadisticas_globales(db: Session = Depends(get_db), usuario_actual: models.Usuario = Depends(obtener_usuario_actual)):
    # Contamos absolutamente todos los equipos en el inventario
    total_equipos = db.query(models.Equipo).count()
    
    # Contamos los tickets que siguen activos (cualquier estado que no sea cerrado)
    tickets_abiertos = db.query(models.Ticket).filter(
        models.Ticket.estatus.notin_(["Resuelto", "Entregado"])
    ).count()
    
    # Contamos los tickets que ya se terminaron exitosamente
    tickets_resueltos = db.query(models.Ticket).filter(
        models.Ticket.estatus.in_(["Resuelto", "Entregado"])
    ).count()
    
    return {
        "total_equipos": total_equipos,
        "tickets_abiertos": tickets_abiertos,
        "tickets_resueltos": tickets_resueltos
    }





# --- LLAVE MAESTRA DEL ADMINISTRADOR: RECUPERAR CUENTAS ---
@app.put("/usuarios/forzar_acceso/{usuario_id}")
def forzar_acceso_tecnico(usuario_id: int, nuevo_correo: str, nueva_password: str, db: Session = Depends(get_db)):
    usuario = db.query(models.Usuario).filter(models.Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    # Le sobreescribimos el correo y le encriptamos la nueva contraseña
    usuario.correo = nuevo_correo
    usuario.password_hash = obtener_password_hash(nueva_password)
    db.commit()
    
    return {
        "mensaje": "¡Hackeo exitoso!",
        "tecnico": usuario.nombre_completo,
        "nuevo_correo": usuario.correo,
        "nueva_password": nueva_password
    }










