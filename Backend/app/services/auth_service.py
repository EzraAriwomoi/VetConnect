from flask import jsonify, request
from app import db, bcrypt
from app.models import Animal, AnimalOwner, Appointment, Review, UserActivity, Veterinarian
from werkzeug.security import generate_password_hash

def register_user(user_type):
    data = request.get_json()
    
    # Hash the password before storing it
    hashed_password = generate_password_hash(data['password'])

    if user_type == 'animal_owner':
        new_user = AnimalOwner(
            name=data['name'],
            email=data['email'],
            phone=data['phone'], 
            location=data['location'],
            password=hashed_password
        )
    elif user_type == 'veterinarian':
        new_user = Veterinarian(
            name=data['name'],
            email=data['email'],
            password=hashed_password,
            license_number=data['license_number'], 
            national_id=data['national_id'], 
            clinic=data['clinic'], 
            specialization=data['specialization']
        )

    try:
        db.session.add(new_user)
        db.session.commit()
        return jsonify({'message': 'User registered successfully'}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'message': f'Error registering user: {str(e)}'}), 500
    

def login_user():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')

    # Try to find user in AnimalOwner table
    user = AnimalOwner.query.filter_by(email=email).first()
    user_type = "animal_owner"

    # If user is not found, try the Veterinarian table
    if not user:
        user = Veterinarian.query.filter_by(email=email).first()
        user_type = "veterinarian"

    if user and bcrypt.check_password_hash(user.password, password):
        return jsonify({
            'message': 'Login successful',
            'user_id': user.id,
            'user_type': user_type,
            'name': user.name
        }), 200

    return jsonify({'message': 'Invalid credentials. Please try again'}), 401

def register_animal(user_id, animal_data):
    # Register the animal
    new_animal = Animal(owner_id=user_id, **animal_data)
    db.session.add(new_animal)

    # Log the activity
    activity = UserActivity(
        user_id=user_id,
        activity_type='animal_registration',
        description=f"Registered animal: {animal_data['name']}"
    )
    db.session.add(activity)

    try:
        print(f"Before commit - UserActivity: {activity}")  # Debug log
        db.session.commit()
        print("Successfully committed activity!")

        # Check if activity is stored
        stored_activities = UserActivity.query.filter_by(user_id=user_id).all()
        print(f"Stored activities for user {user_id}: {stored_activities}")

    except Exception as e:
        db.session.rollback()
        print(f"Error committing UserActivity: {e}")


def create_appointment(owner_id, animal_id, veterinarian_id, date, time, appointment_type):
    # Create the appointment
    new_appointment = Appointment(
        owner_id=owner_id,
        animal_id=animal_id,
        veterinarian_id=veterinarian_id,
        date=date,
        time=time,
        appointment_type=appointment_type
    )
    db.session.add(new_appointment)
    
    # Log this appointment as an activity
    activity = UserActivity(
        user_id=owner_id,
        activity_type='appointment',
        description=f"Scheduled appointment for animal {animal_id} with veterinarian {veterinarian_id} on {date} at {time}"
    )
    db.session.add(activity)
    db.session.commit()

def add_review(owner_id, veterinarian_id, review_text):
    # Add the review to the system
    new_review = Review(
        owner_id=owner_id,
        veterinarian_id=veterinarian_id,
        review_text=review_text
    )
    db.session.add(new_review)

    # Log this review as an activity
    activity = UserActivity(
        user_id=owner_id,
        activity_type='review',
        description=f"Reviewed veterinarian {veterinarian_id}: {review_text}"
    )
    db.session.add(activity)
    db.session.commit()
