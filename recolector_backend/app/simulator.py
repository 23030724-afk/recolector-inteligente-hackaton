"""
Simulador sencillo de avance de rutas.
Uso:
  python -m app.simulator RUTA-01

Avanza positionId 1..8 y genera alertas en 2, 4 y 8.
Ideal para demo si quieren enseñar backend actualizando estados sin GPS real.
"""
import sys
import time
from datetime import datetime

from app.database import SessionLocal
from app.models import Alert, Route


def main(route_id: str):
    with SessionLocal() as db:
        route = db.get(Route, route_id)
        if not route:
            print(f"Ruta {route_id} no encontrada")
            return

        for position_id in range(1, 9):
            route.current_position_id = position_id
            route.status = "EN_RUTA" if position_id < 8 else "FINALIZADA"
            route.updated_at = datetime.utcnow()

            if position_id == 2:
                db.add(Alert(type="ROUTE_START", title="Ruta iniciada", message=f"El camión {route.truck_id} salió a ruta.", route_id=route.route_id, truck_id=route.truck_id, priority=1))
            if position_id == 4:
                db.add(Alert(type="TRUCK_PROXIMITY", title="Camión cercano", message="El camión está a menos de 15 minutos de tu zona.", route_id=route.route_id, truck_id=route.truck_id, priority=2))
            if position_id == 8:
                db.add(Alert(type="ROUTE_COMPLETED", title="Servicio finalizado", message=f"La ruta {route.route_id} concluyó la jornada.", route_id=route.route_id, truck_id=route.truck_id, priority=1))

            db.commit()
            print(f"{route.route_id}: positionId {position_id} actualizado")
            time.sleep(3)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "RUTA-01")
