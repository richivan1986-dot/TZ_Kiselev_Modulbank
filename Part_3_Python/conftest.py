import os
import pytest
import psycopg
def get_connection_params() -> dict:
    return {
        "host": os.getenv("DB_HOST", "localhost"),
        "port": int(os.getenv("DB_PORT", 5432)),
        "dbname": os.getenv("DB_NAME", "testdb"),
        "user": os.getenv("DB_USER", "testuser"),
        "password": os.getenv("DB_PASSWORD", "secret1"),
    }

@pytest.fixture(scope="function")
def db_connection():
    params = get_connection_params()
    conn = psycopg.connect(**params, connect_timeout=5)
    try:
        yield conn
    finally:
        conn.close()
