from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session, selectinload

from app.database import get_db
from app.models import Alert, Route, User
from app.schemas import AlertOut, OperatorActionOut, RouteDetailOut, RouteOut
from app.security import require_role

router = APIRouter(prefix="/operator", tags=["Operator"])


def get_assigned_route(db: Session, route_id: str, operator: User) -> Route:
    route = (
        db.query(Route)
        .options(selectinload(Route.positions))
        .filter(Route.route_id == route_id)
        .first()
    )
    if not route:
        raise HTTPException(status_code=404, detail="Ruta no encontrada")
    if route.assigned_operator_id != operator.id:
        raise HTTPException(status_code=403, detail="Esta ruta no está asignada a este operador")
    return route


def create_alert(
    db: Session,
    route: Route,
    operator: User,
    type_: str,
    title: str,
    message: str,
    priority: int,
) -> Alert:
    alert = Alert(
        type=type_,
        title=title,
        message=message,
        route_id=route.route_id,
        truck_id=route.truck_id,
        operator_id=operator.id,
        priority=priority,
        status="NUEVA",
    )
    db.add(alert)
    db.flush()
    return alert


def action_response(db: Session, route: Route, alert: Alert | None, message: str) -> OperatorActionOut:
    db.commit()
    db.refresh(route)
    if alert:
        db.refresh(alert)
    return OperatorActionOut(ok=True, route=route, alert=alert, message=message)


@router.get("/routes", response_model=list[RouteOut])
def my_routes(
    db: Session = Depends(get_db),
    operator: User = Depends(require_role("operador")),
):
    return (
        db.query(Route)
        .filter(Route.assigned_operator_id == operator.id)
        .order_by(Route.route_id.asc())
        .all()
    )


@router.get("/routes/{route_id}", response_model=RouteDetailOut)
def route_detail(
    route_id: str,
    db: Session = Depends(get_db),
    operator: User = Depends(require_role("operador")),
):
    route = get_assigned_route(db, route_id, operator)
    route.positions = sorted(route.positions, key=lambda p: p.position_id)
    return route


@router.get("/alerts", response_model=list[AlertOut])
def my_sent_alerts(
    db: Session = Depends(get_db),
    operator: User = Depends(require_role("operador")),
):
    return (
        db.query(Alert)
        .filter(Alert.operator_id == operator.id)
        .order_by(Alert.created_at.desc())
        .limit(30)
        .all()
    )


@router.post("/routes/{route_id}/start", response_model=OperatorActionOut)
def start_route(
    route_id: str,
    db: Session = Depends(get_db),
    operator: User = Depends(require_role("operador")),
):
    route = get_assigned_route(db, route_id, operator)
    route.status = "EN_RUTA"
    route.current_position_id = 2
    route.updated_at = datetime.utcnow()
    alert = create_alert(
        db,
        route,
        operator,
        "ROUTE_START",
        "Ruta iniciada",
        f"El camión {route.truck_id} inició la ruta {route.route_id}.",
        1,
    )
    return action_response(db, route, alert, "Jornada iniciada correctamente")


@router.post("/routes/{route_id}/advance/{position_id}", response_model=OperatorActionOut)
def advance_route(
    route_id: str,
    position_id: int,
    db: Session = Depends(get_db),
    operator: User = Depends(require_role("operador")),
):
    route = get_assigned_route(db, route_id, operator)
    valid_positions = {p.position_id for p in route.positions}
    if position_id not in valid_positions:
        raise HTTPException(status_code=422, detail="positionId inválido para esta ruta")

    route.current_position_id = position_id
    route.status = "EN_RUTA" if position_id < 8 else "FINALIZADA"
    route.updated_at = datetime.utcnow()

    alert = None
    if position_id == 4:
        alert = create_alert(
            db,
            route,
            operator,
            "TRUCK_PROXIMITY",
            "Camión cercano",
            f"El camión {route.truck_id} está a menos de 15 minutos de la zona asignada.",
            2,
        )
    elif position_id == 8:
        alert = create_alert(
            db,
            route,
            operator,
            "ROUTE_COMPLETED",
            "Servicio finalizado",
            f"El camión {route.truck_id} finalizó la ruta {route.route_id}.",
            1,
        )

    return action_response(db, route, alert, "Avance de ruta actualizado")


@router.post("/routes/{route_id}/delay", response_model=OperatorActionOut)
def delay_route(
    route_id: str,
    db: Session = Depends(get_db),
    operator: User = Depends(require_role("operador")),
):
    route = get_assigned_route(db, route_id, operator)
    route.status = "RETRASO"
    route.updated_at = datetime.utcnow()
    alert = create_alert(
        db,
        route,
        operator,
        "DELAY",
        "Retraso operativo",
        f"La ruta {route.route_id} presenta un retraso aproximado de 25 minutos.",
        2,
    )
    return action_response(db, route, alert, "Retraso reportado")


@router.post("/routes/{route_id}/breakdown", response_model=OperatorActionOut)
def breakdown_route(
    route_id: str,
    db: Session = Depends(get_db),
    operator: User = Depends(require_role("operador")),
):
    route = get_assigned_route(db, route_id, operator)
    route.status = "AVERIA"
    route.updated_at = datetime.utcnow()
    alert = create_alert(
        db,
        route,
        operator,
        "MECHANICAL_FAILURE",
        "Avería mecánica",
        f"El camión {route.truck_id} presenta falla mecánica. Se requiere apoyo logístico.",
        3,
    )
    return action_response(db, route, alert, "Avería reportada")


@router.post("/routes/{route_id}/incident", response_model=OperatorActionOut)
def incident_route(
    route_id: str,
    db: Session = Depends(get_db),
    operator: User = Depends(require_role("operador")),
):
    route = get_assigned_route(db, route_id, operator)
    route.status = "INCIDENCIA"
    route.updated_at = datetime.utcnow()
    alert = create_alert(
        db,
        route,
        operator,
        "INCIDENT",
        "Incidencia en ruta",
        f"Se registró una incidencia menor en {route.route_id}: obstrucción vial o exceso de residuos.",
        2,
    )
    return action_response(db, route, alert, "Incidencia reportada")


@router.post("/routes/{route_id}/complete", response_model=OperatorActionOut)
def complete_route(
    route_id: str,
    db: Session = Depends(get_db),
    operator: User = Depends(require_role("operador")),
):
    route = get_assigned_route(db, route_id, operator)
    route.status = "FINALIZADA"
    route.current_position_id = 8
    route.updated_at = datetime.utcnow()
    alert = create_alert(
        db,
        route,
        operator,
        "ROUTE_COMPLETED",
        "Servicio finalizado",
        f"El operador finalizó la ruta {route.route_id}.",
        1,
    )
    return action_response(db, route, alert, "Ruta finalizada")
