import hashlib
import hmac
import os
import re
from datetime import datetime, timedelta, timezone
from typing import Annotated

import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.models import User

ALGORITHM = "HS256"
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")
EMAIL_RE = re.compile(r"^[^\s@]+@[^\s@]+\.[^\s@]+$")
ADDRESS_RE = re.compile(r"^(?=.*[A-Za-zÁÉÍÓÚáéíóúÑñ])(?=.*\d).{8,}$")


def hash_password(password: str) -> str:
    salt = os.urandom(16).hex()
    digest = hashlib.pbkdf2_hmac("sha256", password.encode(), salt.encode(), 120_000).hex()
    return f"pbkdf2_sha256${salt}${digest}"


def verify_password(password: str, stored: str) -> bool:
    try:
        algo, salt, digest = stored.split("$")
        if algo != "pbkdf2_sha256":
            return False
        candidate = hashlib.pbkdf2_hmac("sha256", password.encode(), salt.encode(), 120_000).hex()
        return hmac.compare_digest(candidate, digest)
    except ValueError:
        return False


def create_access_token(user: User) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.jwt_expire_minutes)
    payload = {
        "sub": str(user.id),
        "email": user.email,
        "role": user.role,
        "exp": expire,
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=ALGORITHM)


def get_current_user(
    token: Annotated[str, Depends(oauth2_scheme)],
    db: Annotated[Session, Depends(get_db)],
) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Token inválido o expirado",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=[ALGORITHM])
        user_id = int(payload.get("sub"))
    except Exception as exc:
        raise credentials_exception from exc

    user = db.get(User, user_id)
    if not user or not user.active:
        raise credentials_exception
    return user


def require_role(*roles: str):
    def dependency(current_user: Annotated[User, Depends(get_current_user)]) -> User:
        if current_user.role not in roles:
            raise HTTPException(status_code=403, detail="No tienes permisos para esta acción")
        return current_user
    return dependency


def validate_email(email: str) -> str:
    email = email.strip().lower()
    if not EMAIL_RE.match(email):
        raise HTTPException(status_code=422, detail="Correo inválido")
    return email


def validate_address(address: str) -> str:
    value = " ".join(address.strip().split())
    if not ADDRESS_RE.match(value):
        raise HTTPException(
            status_code=422,
            detail="Dirección inválida. Debe incluir calle y número. Ejemplo: Calle Luna 123",
        )
    return value
