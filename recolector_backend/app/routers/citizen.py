from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Alert, Colonia, Domicilio, Rating, Report, Route, User
from app.schemas import (
    AlertOut,
    DomicilioCreate,
    DomicilioOut,
    EtaOut,
    RatingCreate,
    RatingOut,
    ReportCreate,
    ReportOut,
)
from app.security import get_current_user, require_role, validate_address

router = APIRouter(prefix="/citizen", tags=["Citizen"])


def normalize(text: str) -> str:
    repl = str.maketrans("áéíóúüÁÉÍÓÚÜ", "aeiouuAEIOUU")
    return text.strip().translate(repl).lower()


def find_colonia(db: Session, colonia_name: str) -> Colonia:
    wanted = normalize(colonia_name)
    colonias = db.query(Colonia).all()
    for c in colonias:
        if normalize(c.colonia) == wanted:
            return c
    raise HTTPException(status_code=422, detail="Colonia no válida o fuera de cobertura")


def ensure_owner(db: Session, domicilio_id: int, user: User) -> Domicilio:
    domicilio = db.get(Domicilio, domicilio_id)
    if not domicilio or domicilio.user_id != user.id:
        raise HTTPException(status_code=404, detail="Domicilio no encontrado")
    return domicilio


@router.get("/domicilios", response_model=list[DomicilioOut])
def list_domicilios(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role("ciudadano")),
):
    return db.query(Domicilio).filter(Domicilio.user_id == current_user.id).all()


@router.post("/domicilios", response_model=DomicilioOut)
def create_domicilio(
    payload: DomicilioCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role("ciudadano")),
):
    direccion = validate_address(payload.direccion)
    colonia = find_colonia(db, payload.colonia)

    domicilio = Domicilio(
        user_id=current_user.id,
        tipo=payload.tipo.strip() or "Casa principal",
        direccion=direccion,
        colonia=colonia.colonia,
        lat=payload.lat,
        lng=payload.lng,
        route_id=colonia.route_id,
    )
    db.add(domicilio)
    db.commit()
    db.refresh(domicilio)
    return domicilio


@router.get("/domicilios/{domicilio_id}/eta", response_model=EtaOut)
def get_eta(
    domicilio_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role("ciudadano")),
):
    domicilio = ensure_owner(db, domicilio_id, current_user)
    route = db.get(Route, domicilio.route_id)
    colonia = db.query(Colonia).filter(Colonia.colonia == domicilio.colonia).first()
    if not route or not colonia:
        raise HTTPException(status_code=404, detail="Ruta no encontrada")

    if route.current_position_id >= 8:
        eta = "El servicio de tu sector ya finalizó."
    elif route.current_position_id >= 4:
        eta = "El camión llegará a tu zona en aproximadamente 15 minutos."
    elif route.status in {"RETRASO", "AVERIA"}:
        eta = "Hay una incidencia operativa. Revisa tus alertas antes de sacar tus residuos."
    else:
        eta = f"Ventana estimada de recolección: {colonia.horario_estimado}."

    return EtaOut(
        domicilio_id=domicilio.id,
        route_id=route.route_id,
        route_name=route.name,
        truck_id=route.truck_id,
        colonia=domicilio.colonia,
        horario_estimado=colonia.horario_estimado,
        eta_message=eta,
        current_position_id=route.current_position_id,
        privacy_note="Privacidad por diseño: no se expone el mapa ni la ubicación exacta del camión.",
    )


@router.get("/alerts", response_model=list[AlertOut])
def my_alerts(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role("ciudadano")),
):
    route_ids = [d.route_id for d in db.query(Domicilio).filter(Domicilio.user_id == current_user.id).all()]
    if not route_ids:
        return []
    return (
        db.query(Alert)
        .filter(Alert.route_id.in_(route_ids))
        .order_by(Alert.created_at.desc())
        .limit(20)
        .all()
    )


@router.post("/reports", response_model=ReportOut)
def create_report(
    payload: ReportCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role("ciudadano")),
):
    ensure_owner(db, payload.domicilio_id, current_user)
    report = Report(
        user_id=current_user.id,
        domicilio_id=payload.domicilio_id,
        type=payload.type.strip(),
        comment=payload.comment.strip(),
    )
    db.add(report)
    db.commit()
    db.refresh(report)
    return report


@router.post("/ratings", response_model=RatingOut)
def create_rating(
    payload: RatingCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role("ciudadano")),
):
    ensure_owner(db, payload.domicilio_id, current_user)
    rating = Rating(
        user_id=current_user.id,
        domicilio_id=payload.domicilio_id,
        stars=payload.stars,
        comment=payload.comment,
    )
    db.add(rating)
    db.commit()
    db.refresh(rating)
    return rating
