from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    database_url: str = "postgresql+asyncpg://gyaan:gyaan123@localhost:5432/gyaan_guru"
    redis_url: str = "redis://localhost:6379/0"
    jwt_secret: str = "dev-secret"
    jwt_algorithm: str = "HS256"
    jwt_expire_hours: int = 720
    port: int = 8000
    environment: str = "development"
    # Base URL for share links (override in .env for production)
    public_url: str = "http://192.168.100.53:8000"

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")


settings = Settings()
