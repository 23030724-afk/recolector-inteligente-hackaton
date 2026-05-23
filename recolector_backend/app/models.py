from datetime import datetime
from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    email: Mapped[str] = mapped_column(String(160), unique=True, index=True, nullable=False)
    phone: Mapped[str | None] = mapped_column(String(30), nullable=True)
    password_hash: Mapped[str] = mapped_column(String(200), nullable=False)
    role: Mapped[str] = mapped_column(String(30), index=True, nullable=False)  # ciudadano, operador, admin
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    domicilios: Mapped[list["Domicilio"]] = relationship(back_populates="user")
    assigned_routes: Mapped[list["Route"]] = relationship(back_populates="assigned_operator")


class Colonia(Base):
    __tablename__ = "colonias"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    colonia: Mapped[str] = mapped_column(String(120), unique=True, index=True, nullable=False)
    route_id: Mapped[str] = mapped_column(String(30), ForeignKey("routes.route_id"), nullable=False)
    horario_estimado: Mapped[str] = mapped_column(String(120), nullable=False)


class Route(Base):
    __tablename__ = "routes"

    route_id: Mapped[str] = mapped_column(String(30), primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(160), nullable=False)
    truck_id: Mapped[int] = mapped_column(Integer, index=True, nullable=False)
    status: Mapped[str] = mapped_column(String(50), default="PENDIENTE")
    assigned_operator_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("users.id"), nullable=True)
    current_position_id: Mapped[int] = mapped_column(Integer, default=1)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    assigned_operator: Mapped[User | None] = relationship(back_populates="assigned_routes")
    positions: Mapped[list["RoutePosition"]] = relationship(back_populates="route", cascade="all, delete-orphan")


class RoutePosition(Base):
    __tablename__ = "route_positions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    route_id: Mapped[str] = mapped_column(String(30), ForeignKey("routes.route_id"), index=True)
    position_id: Mapped[int] = mapped_column(Integer, index=True)
    lat: Mapped[float] = mapped_column(Float, nullable=False)
    lng: Mapped[float] = mapped_column(Float, nullable=False)
    speed: Mapped[int] = mapped_column(Integer, default=0)
    timestamp: Mapped[str] = mapped_column(String(40), nullable=False)

    route: Mapped[Route] = relationship(back_populates="positions")


class Domicilio(Base):
    __tablename__ = "domicilios"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id"), index=True)
    tipo: Mapped[str] = mapped_column(String(80), default="Casa principal")
    direccion: Mapped[str] = mapped_column(String(220), nullable=False)
    colonia: Mapped[str] = mapped_column(String(120), nullable=False)
    lat: Mapped[float | None] = mapped_column(Float, nullable=True)
    lng: Mapped[float | None] = mapped_column(Float, nullable=True)
    route_id: Mapped[str] = mapped_column(String(30), ForeignKey("routes.route_id"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    user: Mapped[User] = relationship(back_populates="domicilios")


class Alert(Base):
    __tablename__ = "alerts"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    type: Mapped[str] = mapped_column(String(50), index=True, nullable=False)
    title: Mapped[str] = mapped_column(String(140), nullable=False)
    message: Mapped[str] = mapped_column(Text, nullable=False)
    route_id: Mapped[str] = mapped_column(String(30), ForeignKey("routes.route_id"), index=True)
    truck_id: Mapped[int] = mapped_column(Integer, index=True)
    operator_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("users.id"), nullable=True)
    priority: Mapped[int] = mapped_column(Integer, default=1)  # 1 baja, 2 media, 3 alta
    status: Mapped[str] = mapped_column(String(40), default="NUEVA")
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class Report(Base):
    __tablename__ = "reports"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id"), index=True)
    domicilio_id: Mapped[int] = mapped_column(Integer, ForeignKey("domicilios.id"), index=True)
    type: Mapped[str] = mapped_column(String(80), nullable=False)
    comment: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[str] = mapped_column(String(40), default="NUEVO")
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class Rating(Base):
    __tablename__ = "ratings"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id"), index=True)
    domicilio_id: Mapped[int] = mapped_column(Integer, ForeignKey("domicilios.id"), index=True)
    stars: Mapped[int] = mapped_column(Integer, nullable=False)
    comment: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
