from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "Recolector Inteligente API"
    database_url: str = "sqlite:///./recolector.db"
    jwt_secret: str = "CAMBIA_ESTE_SECRETO_EN_PRODUCCION"
    jwt_expire_minutes: int = 1440

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")


settings = Settings()
