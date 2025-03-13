from . import db
from datetime import datetime, timedelta

class AnimalOwner(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    phone = db.Column(db.String(20), unique=True, nullable=False)
    location = db.Column(db.String(200), nullable=False)
    password = db.Column(db.String(200), nullable=False)
    reset_token_expiry = db.Column(db.DateTime, nullable=True)

class Veterinarian(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password = db.Column(db.String(200), nullable=False)
    license_number = db.Column(db.String(50), unique=True, nullable=False)
    national_id = db.Column(db.String(50), unique=True, nullable=False)
    clinic = db.Column(db.String(200), nullable=False)
    specialization = db.Column(db.String(200), nullable=False)
    reset_token_expiry = db.Column(db.DateTime, nullable=True)
