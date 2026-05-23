from sqlalchemy import func
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Alert, Rating, Report, Route, User
from app.schemas import (
    AlertOut,
    AssignOperatorIn,
    DashboardOut,
    ReportOut,
    ReportStatusUpdate,
    RouteOut,
    UserOut,
)
from app.security import require_role

router = APIRouter(prefix="/admin", tags=["Admin"])


@router.get("/dashboard", response_model=DashboardOut)
def dashboard(db: Session = Depends(get_db), admin: User = Depends(require_role("admin"))):
    routes_total = db.query(Route).count()
    active_routes = db.query(Route).filter(Route.status.in_(["EN_RUTA", "RETRASO", "AVERIA", "INCIDENCIA"])).count()
    trucks_total = db.query(func.count(func.distinct(Route.truck_id))).scalar() or 0
    operators_total = db.query(User).filter(User.role == "operador").count()
    alerts_open = db.query(Alert).filter(Alert.status != "CERRADA").count()
    reports_open = db.query(Report).filter(Report.status.in_(["NUEVO", "EN_REVISION"])).count()
    avg = db.query(func.avg(Rating.stars)).scalar()

    return DashboardOut(
        routes_total=routes_total,
        active_routes=active_routes,
        trucks_total=trucks_total,
        operators_total=operators_total,
        alerts_open=alerts_open,
        reports_open=reports_open,
        average_rating=round(float(avg or 0), 2),
    )


@router.get("/users", response_model=list[UserOut])
def users(db: Session = Depends(get_db), admin: User = Depends(require_role("admin"))):
    return db.query(User).order_by(User.role.asc(), User.name.asc()).all()


@router.get("/operators", response_model=list[UserOut])
def operators(db: Session = Depends(get_db), admin: User = Depends(require_role("admin"))):
    return db.query(User).filter(User.role == "operador").order_by(User.name.asc()).all()


@router.get("/routes", response_model=list[RouteOut])
def routes(db: Session = Depends(get_db), admin: User = Depends(require_role("admin"))):
    return db.query(Route).order_by(Route.route_id.asc()).all()


@router.post("/routes/{route_id}/assign-operator", response_model=RouteOut)
def assign_operator(
    route_id: str,
    payload: AssignOperatorIn,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role("admin")),
):
    route = db.get(Route, route_id)
    if not route:
        raise HTTPException(status_code=404, detail="Ruta no encontrada")
    operator = db.get(User, payload.operator_id)
    if not operator or operator.role != "operador":
        raise HTTPException(status_code=422, detail="Operador inválido")
    route.assigned_operator_id = operator.id
    db.commit()
    db.refresh(route)
    return route


@router.get("/alerts", response_model=list[AlertOut])
def alerts(db: Session = Depends(get_db), admin: User = Depends(require_role("admin"))):
    return db.query(Alert).order_by(Alert.created_at.desc()).limit(100).all()


@router.patch("/alerts/{alert_id}/close", response_model=AlertOut)
def close_alert(alert_id: int, db: Session = Depends(get_db), admin: User = Depends(require_role("admin"))):
    alert = db.get(Alert, alert_id)
    if not alert:
        raise HTTPException(status_code=404, detail="Alerta no encontrada")
    alert.status = "CERRADA"
    db.commit()
    db.refresh(alert)
    return alert


@router.get("/reports", response_model=list[ReportOut])
def reports(db: Session = Depends(get_db), admin: User = Depends(require_role("admin"))):
    return db.query(Report).order_by(Report.created_at.desc()).limit(100).all()


@router.patch("/reports/{report_id}/status", response_model=ReportOut)
def update_report_status(
    report_id: int,
    payload: ReportStatusUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role("admin")),
):
    report = db.get(Report, report_id)
    if not report:
        raise HTTPException(status_code=404, detail="Reporte no encontrado")
    report.status = payload.status
    db.commit()
    db.refresh(report)
    return report
