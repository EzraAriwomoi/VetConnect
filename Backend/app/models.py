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

class HelpDeskPost(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, nullable=False)
    user_type = db.Column(db.String(20), nullable=False)
    title = db.Column(db.String(200), nullable=False)
    content = db.Column(db.Text, nullable=False)
    animal_type = db.Column(db.String(100), nullable=False)
    image_url = db.Column(db.String(500), nullable=True)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)
    likes = db.Column(db.Integer, default=0)
    
    comments = db.relationship('HelpDeskComment', backref='post', lazy=True, cascade='all, delete-orphan')

class HelpDeskComment(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    post_id = db.Column(db.Integer, db.ForeignKey('help_desk_post.id'), nullable=False)
    user_id = db.Column(db.Integer, nullable=False)
    user_type = db.Column(db.String(20), nullable=False)
    comment = db.Column(db.Text, nullable=False)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)

class Notification(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, nullable=False)
    user_type = db.Column(db.String(20), nullable=False)
    title = db.Column(db.String(200), nullable=False)
    body = db.Column(db.Text, nullable=False)
    type = db.Column(db.String(50), nullable=False)  # 'message', 'appointment', 'review', etc.
    related_id = db.Column(db.String(100), nullable=True)  # ID of the related entity
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)
    is_read = db.Column(db.Boolean, default=False)

class ReviewReply(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    review_id = db.Column(db.Integer, db.ForeignKey('review.id'), nullable=False)
    user_id = db.Column(db.Integer, nullable=False)
    user_type = db.Column(db.String(20), nullable=False)  # 'animal_owner' or 'veterinarian'
    reply_text = db.Column(db.Text, nullable=False)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)
    
    review = db.relationship('Review', backref='replies')

class UserActivity(db.Model):
    __tablename__ = 'user_activity'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, nullable=False)  # Can be an owner or veterinarian
    user_type = db.Column(db.String(20), nullable=False)  # 'owner' or 'veterinarian'
    activity_type = db.Column(db.String(50))  # e.g., 'animal_registration'
    description = db.Column(db.String(255))   # A description of the activity
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)

    def __repr__(self):
        return f"<UserActivity {self.activity_type} for {self.user_type} {self.user_id}>"

