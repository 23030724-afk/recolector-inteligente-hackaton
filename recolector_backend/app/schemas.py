from datetime import datetime
from pydantic import BaseModel, Field


class UserOut(BaseModel):
    id: int
    name: str
    email: str
    phone: str | None
    role: str

    model_config = {"from_attributes": True}


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut


class LoginIn(BaseModel):
    email: str
    password: str


class RegisterIn(BaseModel):
    name: str = Field(min_length=3, max_length=120)
    email: str
    phone: str | None = None
    password: str = Field(min_length=6, max_length=80)
    role: str = "ciudadano"


class PositionOut(BaseModel):
    position_id: int
    lat: float
    lng: float
    speed: int
    timestamp: str

    model_config = {"from_attributes": True}


class RouteOut(BaseModel):
    route_id: str
    name: str
    truck_id: int
    status: str
    current_position_id: int
    assigned_operator_id: int | None = None

    model_config = {"from_attributes": True}


class RouteDetailOut(RouteOut):
    positions: list[PositionOut]


class ColoniaOut(BaseModel):
    colonia: str
    route_id: str
    horario_estimado: str

    model_config = {"from_attributes": True}


class DomicilioCreate(BaseModel):
    tipo: str = "Casa principal"
    direccion: str
    colonia: str
    lat: float | None = None
    lng: float | None = None


class DomicilioOut(BaseModel):
    id: int
    tipo: str
    direccion: str
    colonia: str
    lat: float | None
    lng: float | None
    route_id: str

    model_config = {"from_attributes": True}


class EtaOut(BaseModel):
    domicilio_id: int
    route_id: str
    route_name: str
    truck_id: int
    colonia: str
    horario_estimado: str
    eta_message: str
    current_position_id: int
    privacy_note: str


class AlertCreate(BaseModel):
    type: str
    title: str
    message: str
    route_id: str
    priority: int = 1


class AlertOut(BaseModel):
    id: int
    type: str
    title: str
    message: str
    route_id: str
    truck_id: int
    operator_id: int | None
    priority: int
    status: str
    created_at: datetime

    model_config = {"from_attributes": True}


class ReportCreate(BaseModel):
    domicilio_id: int
    type: str
    comment: str = Field(min_length=5, max_length=800)


class ReportOut(BaseModel):
    id: int
    user_id: int
    domicilio_id: int
    type: str
    comment: str
    status: str
    created_at: datetime

    model_config = {"from_attributes": True}


class ReportStatusUpdate(BaseModel):
    status: str = Field(pattern="^(NUEVO|EN_REVISION|ATENDIDO|CERRADO)$")


class RatingCreate(BaseModel):
    domicilio_id: int
    stars: int = Field(ge=1, le=5)
    comment: str | None = Field(default=None, max_length=400)


class RatingOut(BaseModel):
    id: int
    user_id: int
    domicilio_id: int
    stars: int
    comment: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


class OperatorActionOut(BaseModel):
    ok: bool
    route: RouteOut
    alert: AlertOut | None = None
    message: str


class AssignOperatorIn(BaseModel):
    operator_id: int


class DashboardOut(BaseModel):
    routes_total: int
    active_routes: int
    trucks_total: int
    operators_total: int
    alerts_open: int
    reports_open: int
    average_rating: float
