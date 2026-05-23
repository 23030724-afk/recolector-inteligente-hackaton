from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User
from app.schemas import RegisterIn, TokenOut, UserOut
from app.security import (
    create_access_token,
    get_current_user,
    hash_password,
    validate_email,
    verify_password,
)

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/login", response_model=TokenOut)
async def login(request: Request, db: Session = Depends(get_db)):
    """
    Login compatible con:
    1. Swagger Authorize OAuth2 Password:
       username=correo
       password=contraseña

    2. Flutter / Postman JSON:
       {
         "email": "admin@demo.com",
         "password": "123456"
       }
    """

    content_type = request.headers.get("content-type", "")

    email = ""
    password = ""

    if "application/x-www-form-urlencoded" in content_type or "multipart/form-data" in content_type:
        form = await request.form()
        email = str(form.get("username") or form.get("email") or "").strip()
        password = str(form.get("password") or "").strip()
    else:
        try:
            payload = await request.json()
        except Exception:
            payload = {}

        email = str(payload.get("email") or payload.get("username") or "").strip()
        password = str(payload.get("password") or "").strip()

    if not email or not password:
        raise HTTPException(
            status_code=422,
            detail="Debes enviar correo y contraseña.",
        )

    email = validate_email(email)

    user = db.query(User).filter(User.email == email).first()

    if not user or not verify_password(password, user.password_hash):
        raise HTTPException(
            status_code=401,
            detail="Correo o contraseña incorrectos",
        )

    token = create_access_token(user)

    return TokenOut(
        access_token=token,
        token_type="bearer",
        user=user,
    )


@router.post("/register", response_model=TokenOut)
def register(payload: RegisterIn, db: Session = Depends(get_db)):
    email = validate_email(payload.email)
    role = payload.role.strip().lower()

    if role not in {"ciudadano", "operador", "admin"}:
        raise HTTPException(status_code=422, detail="Rol inválido")

    if db.query(User).filter(User.email == email).first():
        raise HTTPException(status_code=409, detail="Ese correo ya está registrado")

    user = User(
        name=payload.name.strip(),
        email=email,
        phone=payload.phone,
        password_hash=hash_password(payload.password),
        role=role,
    )

    db.add(user)
    db.commit()
    db.refresh(user)

    return TokenOut(
        access_token=create_access_token(user),
        token_type="bearer",
        user=user,
    )


@router.get("/me", response_model=UserOut)
def me(current_user: User = Depends(get_current_user)):
    return current_user