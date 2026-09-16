# Autor: URIEL GUTIÉRREZ CASTILLO
# Proyecto: Helpdesk y Control de Inventario - H. Ayuntamiento

from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from database import engine, Base, SessionLocal
import models
import schemas

# Esto crea las tablas en PostgreSQL si no existen
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="API Helpdesk Ayuntamiento",
    description="Sistema de gestión de inventario y tickets",
    version="1.0.0"
)

# Dependencia: Abre y cierra la conexión a la base de datos
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.get("/")
def ruta_principal():
    return {"mensaje": "¡El cerebro del Helpdesk está vivo y conectado a la base de datos!"}

# RUTA 1: Registrar un equipo nuevo (POST)
@app.post("/equipos/", response_model=schemas.EquipoResponse)
def registrar_equipo(equipo: schemas.EquipoCreate, db: Session = Depends(get_db)):
    nuevo_equipo = models.Equipo(**equipo.model_dump())
    db.add(nuevo_equipo)
    db.commit()
    db.refresh(nuevo_equipo)
    return nuevo_equipo

# RUTA 2: Buscar un equipo por su ID (GET) - ¡El motor de los códigos QR!
@app.get("/equipos/{equipo_id}", response_model=schemas.EquipoResponse)
def obtener_equipo(equipo_id: int, db: Session = Depends(get_db)):
    # Buscamos en la base de datos el equipo que coincida con el ID solicitado
    equipo = db.query(models.Equipo).filter(models.Equipo.id == equipo_id).first()
    
    # Si alguien busca un ID que no existe, marcamos un error 404
    if not equipo:
        raise HTTPException(status_code=404, detail="Equipo no encontrado en el Ayuntamiento")
    
    return equipo


# RUTA 3: Levantar un nuevo ticket (POST)
@app.post("/tickets/", response_model=schemas.TicketResponse)
def crear_ticket(ticket: schemas.TicketCreate, db: Session = Depends(get_db)):
    # Primero verificamos que el equipo exista en el inventario
    equipo_existente = db.query(models.Equipo).filter(models.Equipo.id == ticket.equipo_id).first()
    if not equipo_existente:
        raise HTTPException(status_code=404, detail="El equipo indicado no existe en el inventario")
    
    # Si existe, creamos el ticket asociado a ese equipo
    nuevo_ticket = models.Ticket(**ticket.model_dump())
    db.add(nuevo_ticket)
    db.commit()
    db.refresh(nuevo_ticket)
    return nuevo_ticket

# RUTA 4: Ver los tickets de un equipo específico (GET)
@app.get("/equipos/{equipo_id}/tickets", response_model=list[schemas.TicketResponse])
def obtener_tickets_de_equipo(equipo_id: int, db: Session = Depends(get_db)):
    tickets = db.query(models.Ticket).filter(models.Ticket.equipo_id == equipo_id).all()
    return tickets

# RUTA 5: Actualizar un ticket (PUT) - Para uso del técnico
@app.put("/tickets/{ticket_id}", response_model=schemas.TicketResponse)
def actualizar_ticket(ticket_id: int, ticket_actualizado: schemas.TicketUpdate, db: Session = Depends(get_db)):
    # Buscamos el ticket en la base de datos
    ticket = db.query(models.Ticket).filter(models.Ticket.id == ticket_id).first()
    
    if not ticket:
        raise HTTPException(status_code=404, detail="El ticket indicado no existe")
    
    # Si el técnico envió un nuevo estatus, lo actualizamos
    if ticket_actualizado.estatus is not None:
        ticket.estatus = ticket_actualizado.estatus
        
    # Si el técnico escribió un diagnóstico, lo guardamos
    if ticket_actualizado.diagnostico_final is not None:
        ticket.diagnostico_final = ticket_actualizado.diagnostico_final
        
    # Guardamos los cambios
    db.commit()
    db.refresh(ticket)
    return ticket

















