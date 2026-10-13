from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class TokenData(BaseModel):
    correo: Optional[str] = None


# --- ESQUEMAS DE USUARIO ---
class UsuarioBase(BaseModel):
    correo: str
    nombre_completo: str
    rol: str

class UsuarioCreate(UsuarioBase):
    password: str

class UsuarioResponse(UsuarioBase):
    id: int
    class Config:
        from_attributes = True




# --- ESQUEMAS DE EQUIPO ---
class EquipoBase(BaseModel):
    folio_inventario: str
    departamento: str
    ip: str
    caracteristicas: str
    
    # --- NUEVAS COLUMNAS AÑADIDAS AQUÍ ---
    tipo_equipo: Optional[str] = None
    marca: Optional[str] = None
    modelo: Optional[str] = None

class EquipoCreate(EquipoBase):
    pass

class Equipo(EquipoBase):
    id: int
    class Config:
        from_attributes = True





# --- ESQUEMAS DE TICKET (NUEVO FORMATO FÍSICO) ---
class TicketCreate(BaseModel):
    equipo_id: int
    nombre_entrega: str
    nombre_recibe: str
    telefono: Optional[str] = None
    departamento: str
    diagnostico_inicial: str
    accesorios: Optional[str] = None
    estado_fisico: Optional[str] = None

class Ticket(BaseModel):
    id: int
    equipo_id: int
    fecha_entrada: datetime
    nombre_entrega: str
    nombre_recibe: str
    telefono: Optional[str] = None
    departamento: str
    diagnostico_inicial: str
    accesorios: Optional[str] = None
    estado_fisico: Optional[str] = None
    
    # --- LA CORRECCIÓN CLAVE ---
    tecnico_asignado: Optional[str] = None
    estatus: str
    ejecucion_servicio: Optional[str] = None
    requerimiento_refaccion: Optional[str] = None
    fecha_salida: Optional[datetime] = None

    class Config:
        from_attributes = True



class TicketUpdate(BaseModel):
    estatus: Optional[str] = None
    tecnico_asignado: Optional[str] = None
    ejecucion_servicio: Optional[str] = None
    requerimiento_refaccion: Optional[str] = None

# --- ¡ESTO ES LO IMPORTANTE! Cero espacios a la izquierda ---
TicketResponse = Ticket
EquipoResponse = Equipo
