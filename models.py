from sqlalchemy import Column, Integer, String, Text, ForeignKey
from database import Base

# --- TABLA 1: INVENTARIO ---
class Equipo(Base):
    __tablename__ = "equipos"

    id = Column(Integer, primary_key=True, index=True)
    folio_inventario = Column(String, unique=True, index=True)
    ip = Column(String, nullable=True)
    caracteristicas = Column(Text, nullable=True)
    departamento = Column(String, index=True)
    url_qr = Column(String, nullable=True)

# --- TABLA 2: DICTÁMENES TÉCNICOS ---
class Ticket(Base):
    __tablename__ = "tickets"

    id = Column(Integer, primary_key=True, index=True)
    # ¡Aquí está el enlace mágico! Conecta el ticket con el ID del equipo
    equipo_id = Column(Integer, ForeignKey("equipos.id")) 
    
    falla_reportada = Column(Text, nullable=False)
    tecnico_asignado = Column(String, nullable=True)
    
    # El estatus nos servirá para las columnas del Kanban (Asignado, Esperando Piezas, Reparado)
    estatus = Column(String, default="Asignado") 
    diagnostico_final = Column(Text, nullable=True)