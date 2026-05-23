from sqlalchemy.orm import Session

from app.models import Colonia, Route, RoutePosition, User
from app.security import hash_password

COLONIAS = [
    {"colonia": "Zona Centro", "route_id": "RUTA-01", "horario_estimado": "Matutino (06:30 - 07:15)"},
    {"colonia": "Las Arboledas", "route_id": "RUTA-01", "horario_estimado": "Matutino (07:00 - 07:30)"},
    {"colonia": "Trojes", "route_id": "RUTA-13", "horario_estimado": "Matutino (06:40 - 07:10)"},
    {"colonia": "San Juanico", "route_id": "RUTA-03", "horario_estimado": "Matutino (06:45 - 07:15)"},
    {"colonia": "Los Olivos", "route_id": "RUTA-04", "horario_estimado": "Matutino (07:00 - 07:40)"},
    {"colonia": "Rancho Seco", "route_id": "RUTA-05", "horario_estimado": "Vespertino (14:15 - 15:00)"},
    {"colonia": "Las Insurgentes", "route_id": "RUTA-12", "horario_estimado": "Matutino (06:35 - 07:10)"},
]

ROUTE_DEFS = [
    ("RUTA-01", "Zona Centro - Las Arboledas", 101, "06:00"),
    ("RUTA-02", "Sector Norte - Av. Tecnológico", 102, "06:05"),
    ("RUTA-03", "Sector Poniente - San Juanico", 103, "06:10"),
    ("RUTA-04", "Oriente - Los Olivos", 104, "06:15"),
    ("RUTA-05", "Sector Sur - Rancho Seco", 105, "06:20"),
    ("RUTA-06", "Norte Extremo - Rumbos de Roque", 106, "06:00"),
    ("RUTA-07", "Nororiente - Ciudad Industrial", 107, "06:10"),
    ("RUTA-08", "Suroriente - Universidad Latina", 108, "06:15"),
    ("RUTA-09", "Poniente - Hospital General", 109, "06:02"),
    ("RUTA-10", "Eje Juan Pablo II - Sede UG Sur", 110, "06:22"),
    ("RUTA-11", "Zona de Oro - Torres Landa", 111, "06:04"),
    ("RUTA-12", "Nororiente - Las Insurgentes", 112, "06:08"),
    ("RUTA-13", "Sector Norte - Trojes e Irrigación", 113, "06:12"),
    ("RUTA-14", "Sur Poniente - La Toscana", 114, "06:16"),
    ("RUTA-15", "Norponiente - Camino a San José de Celaya", 115, "06:18"),
]

BASE_POSITIONS = [
    (1, 20.5111, -100.9037, 0, 0),
    (2, 20.5185, -100.8450, 42, 12),
    (3, 20.5215, -100.8142, 25, 25),
    (4, 20.5212, -100.8175, 15, 38),
    (5, 20.5210, -100.8210, 0, 50),
    (6, 20.5235, -100.8212, 18, 65),
    (7, 20.5260, -100.8215, 24, 78),
    (8, 20.5111, -100.9037, 40, 100),
]


def _timestamp(start_hour_min: str, delta_minutes: int) -> str:
    hour, minute = map(int, start_hour_min.split(":"))
    total = hour * 60 + minute + delta_minutes
    hh = (total // 60) % 24
    mm = total % 60
    return f"2026-05-22T{hh:02d}:{mm:02d}:00Z"


def seed_database(db: Session):
    if db.query(User).count() > 0:
        return

    citizen = User(
        name="Usuario Demo",
        email="demo@correo.com",
        phone="4610000000",
        password_hash=hash_password("123456"),
        role="ciudadano",
    )
    operator = User(
        name="Operador José Martínez",
        email="operador@demo.com",
        phone="4611111111",
        password_hash=hash_password("123456"),
        role="operador",
    )
    operator2 = User(
        name="Operadora Ana Torres",
        email="operador2@demo.com",
        phone="4612222222",
        password_hash=hash_password("123456"),
        role="operador",
    )
    admin = User(
        name="Administrador Logístico",
        email="admin@demo.com",
        phone="4613333333",
        password_hash=hash_password("123456"),
        role="admin",
    )
    db.add_all([citizen, operator, operator2, admin])
    db.flush()

    for idx, (route_id, name, truck_id, start) in enumerate(ROUTE_DEFS):
        assigned = operator.id if route_id in {"RUTA-01", "RUTA-03", "RUTA-05"} else operator2.id if route_id in {"RUTA-04", "RUTA-12", "RUTA-13"} else None
        route = Route(
            route_id=route_id,
            name=name,
            truck_id=truck_id,
            status="PENDIENTE",
            assigned_operator_id=assigned,
            current_position_id=1,
        )
        db.add(route)
        db.flush()
        offset = idx * 0.0025
        for position_id, lat, lng, speed, delta in BASE_POSITIONS:
            db.add(RoutePosition(
                route_id=route_id,
                position_id=position_id,
                lat=lat + offset,
                lng=lng - offset,
                speed=speed,
                timestamp=_timestamp(start, delta),
            ))

    for c in COLONIAS:
        db.add(Colonia(**c))

    db.commit()
