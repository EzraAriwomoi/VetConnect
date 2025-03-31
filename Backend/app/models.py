from datetime import datetime
from . import db
import pytz

LOCAL_TZ = pytz.timezone("Africa/Nairobi")

class AnimalOwner(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    phone = db.Column(db.String(20), unique=True, nullable=False)
    location = db.Column(db.String(200), nullable=False)
    password = db.Column(db.String(200), nullable=False)
    reset_token_expiry = db.Column(db.DateTime, nullable=True)
    firebase_uid = db.Column(db.String(255), unique=True, nullable=True)

    animals = db.relationship('Animal', backref='animal_owner', lazy=True) 

class Veterinarian(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password = db.Column(db.String(200), nullable=False)
    license_number = db.Column(db.String(50), unique=True, nullable=False)
    national_id = db.Column(db.String(50), unique=True, nullable=False)
    clinic = db.Column(db.String(200), nullable=False)
    specialization = db.Column(db.String(200), nullable=False)
    profile_image = db.Column(db.String(300), nullable=True)
    reset_token_expiry = db.Column(db.DateTime, nullable=True)
    firebase_uid = db.Column(db.String(255), unique=True, nullable=True)

class Animal(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    owner_id = db.Column(db.Integer, db.ForeignKey('animal_owner.id'), nullable=False)
    name = db.Column(db.String(100), nullable=False)
    breed = db.Column(db.String(100), nullable=False)
    gender = db.Column(db.String(10), nullable=False)
    color = db.Column(db.String(50), nullable=False)
    species = db.Column(db.String(100), nullable=False)
    date_of_birth = db.Column(db.Date, nullable=False)
    image_url = db.Column(db.String(500), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class FavoriteVeterinarian(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    owner_id = db.Column(db.Integer, db.ForeignKey('animal_owner.id'), nullable=False)
    veterinarian_id = db.Column(db.Integer, db.ForeignKey('veterinarian.id'), nullable=False)

    owner = db.relationship('AnimalOwner', backref='favorite_veterinarians')
    veterinarian = db.relationship('Veterinarian', backref='favorited_by')

class Appointment(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    owner_id = db.Column(db.Integer, db.ForeignKey('animal_owner.id'), nullable=False)
    animal_id = db.Column(db.Integer, db.ForeignKey('animal.id'), nullable=False)
    veterinarian_id = db.Column(db.Integer, db.ForeignKey('veterinarian.id'), nullable=False)
    date = db.Column(db.Date, nullable=False)
    time = db.Column(db.String(10), nullable=False)
    appointment_type = db.Column(db.String(100), nullable=False)
    status = db.Column(db.String(20), default="Pending", nullable=False)
    notes = db.Column(db.Text, default="")
    prescription = db.Column(db.Text, default="")
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    owner = db.relationship('AnimalOwner', backref='appointments')
    animal = db.relationship('Animal', backref='appointments')
    veterinarian = db.relationship('Veterinarian', backref='appointments')

class Review(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    veterinarian_id = db.Column(db.Integer, db.ForeignKey('veterinarian.id'), nullable=False)
    owner_id = db.Column(db.Integer, db.ForeignKey('animal_owner.id'), nullable=False)
    review_text = db.Column(db.Text, nullable=False)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(LOCAL_TZ))

    veterinarian = db.relationship('Veterinarian', backref='reviews')
    owner = db.relationship('AnimalOwner', backref='reviews')