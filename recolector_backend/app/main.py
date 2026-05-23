from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import Base, SessionLocal, engine
from app.routers import admin, auth, citizen, operator, public
from app.seed import seed_database

Base.metadata.create_all(bind=engine)

with SessionLocal() as db:
    seed_database(db)

app = FastAPI(
    title=settings.app_name,
    version="1.0.0",
    description="Backend MVP para app de notificación privada de recolección de residuos por roles: ciudadano, operador y administrador.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(public.router)
app.include_router(auth.router)
app.include_router(citizen.router)
app.include_router(operator.router)
app.include_router(admin.router)


@app.get("/")
def root():
    return {
        "ok": True,
        "name": settings.app_name,
        "docs": "/docs",
        "roles": ["ciudadano", "operador", "admin"],
    }
