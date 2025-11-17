from fastapi import FastAPI
from .database import get_db, init_db

app = FastAPI(
    title="Seshy Backend API",
    version="1.0",
    description="Simple backend used for CPTS 322 Dockerization assignment."
)

@app.on_event("startup")
def startup():
    init_db()

@app.get("/events")
def list_events():
    db = get_db()
    events = db.execute("SELECT * FROM events").fetchall()
    return {"events": [dict(e) for e in events]}

@app.post("/events")
def create_event(title: str):
    db = get_db()
    db.execute("INSERT INTO events (title) VALUES (?)", (title,))
    db.commit()
    return {"status": "success", "title": title}

@app.get("/health")
def health():
    return {"status": "ok", "version": "1.1"}