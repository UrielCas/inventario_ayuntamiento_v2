
# Autor: URIEL GUTIÉRREZ CASTILLO
from datetime import datetime
from sqlalchemy import Column, Integer, String, ForeignKey, Text, DateTime
from sqlalchemy.orm import relationship
from database import Base 

# --- TABLA: USUARIOS (RECOLECTORES, ADMINS, TÉCNICOS) ---
class Usuario(Base):
    __tablename__ = "usuarios"

    id = Column(Integer, primary_key=True, index=True)
    nombre_completo = Column(String, index=True)
    correo = Column(String, unique=True, index=True)
    password_hash = Column(String) 
    rol = Column(String, default="tecnico") # Puede ser: recolector, admin, tecnico


# --- TABLA: EQUIPOS ---
class Equipo(Base):
    __tablename__ = "equipos"
    
    id = Column(Integer, primary_key=True, index=True)
    folio_inventario = Column(String, unique=True, index=True)
    departamento = Column(String)
    ip = Column(String)
    caracteristicas = Column(String)
    
    tipo_equipo = Column(String, nullable=True)
    marca = Column(String, nullable=True)
    modelo = Column(String, nullable=True)
    
    tickets = relationship("Ticket", back_populates="equipo")


# --- TABLA: TICKETS (ÓRDENES DE REPARACIÓN) ---
class Ticket(Base):
    __tablename__ = "tickets"
    
    id = Column(Integer, primary_key=True, index=True)
    equipo_id = Column(Integer, ForeignKey("equipos.id"))
    
    # --- ENLACE AL FLUJO DE ROLES ---
    recolector_id = Column(Integer, ForeignKey("usuarios.id"), nullable=True) # Quién lo registró
    tecnico_id = Column(Integer, ForeignKey("usuarios.id"), nullable=True)    # A quién se le asignó
    
    # --- 1. DATOS DE RECEPCIÓN (Llenado por Recolector/Admin) ---
    fecha_entrada = Column(DateTime, default=datetime.utcnow)
    nombre_entrega = Column(String, index=True)
    nombre_recibe = Column(String)
    telefono = Column(String, nullable=True)
    departamento = Column(String, index=True)
    
    # --- 2. DIAGNÓSTICO Y CONDICIONES ---
    diagnostico_inicial = Column(Text)
    accesorios = Column(Text, nullable=True)  
    estado_fisico = Column(Text, nullable=True) 
    
    # --- 3. ATENCIÓN DEL TÉCNICO Y ESTADO DEL FLUJO ---
    # Estados del flujo: Recibido, Asignado, En Diagnóstico, Espera de Piezas, Reparado, Baja Definitiva, Entregado
    estatus = Column(String, default="Recibido") 
    ejecucion_servicio = Column(Text, nullable=True)
    requerimiento_refaccion = Column(Text, nullable=True)
    fecha_salida = Column(DateTime, nullable=True)

    # --- RELACIONES PARA FASTAPI ---
    equipo = relationship("Equipo", back_populates="tickets")
    recolector = relationship("Usuario", foreign_keys=[recolector_id])
    tecnico = relationship("Usuario", foreign_keys=[tecnico_id])