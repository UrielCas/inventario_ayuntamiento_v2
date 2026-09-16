from pydantic import BaseModel
from typing import Optional

# --- ESQUEMAS PARA EQUIPOS ---
class EquipoCreate(BaseModel):
    folio_inventario: str
    ip: Optional[str] = None
    caracteristicas: Optional[str] = None
    departamento: str
    url_qr: Optional[str] = None

class EquipoResponse(BaseModel):
    id: int
    folio_inventario: str
    ip: Optional[str] = None
    caracteristicas: Optional[str] = None
    departamento: str
    url_qr: Optional[str] = None

    class Config:
        from_attributes = True  # ¡Esto corrige la advertencia de Pydantic!

# --- ESQUEMAS PARA TICKETS (NUEVO) ---
# Lo que pediremos cuando alguien reporte una falla
class TicketCreate(BaseModel):
    equipo_id: int
    falla_reportada: str
    tecnico_asignado: Optional[str] = None

# Lo que el sistema devolverá cuando consultemos un ticket
class TicketResponse(BaseModel):
    id: int
    equipo_id: int
    falla_reportada: str
    tecnico_asignado: Optional[str] = None
    estatus: str
    diagnostico_final: Optional[str] = None

    class Config:
        from_attributes = True


# Esquema para ACTUALIZAR un ticket (el técnico cambia el estatus o añade diagnóstico)
class TicketUpdate(BaseModel):
    estatus: Optional[str] = None
    diagnostico_final: Optional[str] = None
