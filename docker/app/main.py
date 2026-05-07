import os
import structlog
import psycopg2
from fastapi import FastAPI, HTTPException
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST
from starlette.responses import Response
from config import load_db_config

log = structlog.get_logger()
app = FastAPI()

REQUEST_COUNT = Counter("http_requests_total", "Total HTTP requests", ["method", "endpoint", "status"])


@app.get("/")
def root():
    REQUEST_COUNT.labels(method="GET", endpoint="/", status="200").inc()
    return {"status": "ok"}


@app.get("/health")
def health():
    return {"status": "healthy"}


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.get("/db-check")
def db_check():
    try:
        cfg = load_db_config()
        conn = psycopg2.connect(
            host=cfg["DB_HOST"],
            port=int(cfg.get("DB_PORT", 5432)),
            dbname=cfg["DB_NAME"],
            user=cfg["DB_USER"],
            password=cfg["DB_PASSWORD"],
            sslmode="require",
            connect_timeout=5,
        )
        cur = conn.cursor()
        cur.execute("SELECT 1")
        result = cur.fetchone()
        cur.close()
        conn.close()
        REQUEST_COUNT.labels(method="GET", endpoint="/db-check", status="200").inc()
        log.info("db_check_success", result=result[0])
        return {"db": "ok", "result": result[0]}
    except Exception as e:
        REQUEST_COUNT.labels(method="GET", endpoint="/db-check", status="500").inc()
        log.error("db_check_failed", error=str(e))
        raise HTTPException(status_code=500, detail="db check failed")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080, log_config=None)
