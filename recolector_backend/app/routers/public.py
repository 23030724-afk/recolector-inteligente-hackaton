from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Colonia, Route
from app.schemas import ColoniaOut, RouteOut

router = APIRouter(prefix="/public", tags=["Public"])


@router.get("/health")
def health():
    return {"ok": True, "message": "Recolector Inteligente API funcionando"}


@router.get("/colonias", response_model=list[ColoniaOut])
def colonias(db: Session = Depends(get_db)):
    return db.query(Colonia).order_by(Colonia.colonia.asc()).all()


@router.get("/routes", response_model=list[RouteOut])
def routes(db: Session = Depends(get_db)):
    return db.query(Route).order_by(Route.route_id.asc()).all()


@router.get("/guide")
def guide():
    return [
        {
            "categoria": "Orgánicos",
            "ejemplos": "Comida, frutas, verduras, restos de café y hojas",
            "detalle": "Pueden convertirse en composta y reducen malos olores si se separan.",
        },
        {
            "categoria": "Reciclables",
            "ejemplos": "Cartón, plástico, vidrio, latas y papel limpio",
            "detalle": "Deben entregarse limpios y secos para poder reutilizarse.",
        },
        {
            "categoria": "Sanitarios",
            "ejemplos": "Papel higiénico, pañales, toallas sanitarias y cubrebocas",
            "detalle": "Deben ir en bolsa cerrada porque pueden representar riesgo sanitario.",
        },
        {
            "categoria": "Especiales",
            "ejemplos": "Pilas, electrónicos, focos, aceite y medicamentos",
            "detalle": "No deben mezclarse con basura común; requieren centros de acopio.",
        },
    ]
