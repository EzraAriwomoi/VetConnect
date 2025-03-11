from flask import jsonify, request
from app import db, bcrypt
from app.models import AnimalOwner, Veterinarian

def register_user(user_type):
    data = request.get_json()
    name = data.get('name')
    email = data.get('email')
    password = data.get('password')
    hashed_password = bcrypt.generate_password_hash(password).decode('utf-8')

    if user_type == 'animal_owner':
        user = AnimalOwner(
            name=name, 
            email=email, 
            phone=data.get('phone'), 
            location=data.get('location'),
            password=hashed_password
        )
    else:
        user = Veterinarian(
            name=name, 
            email=email, 
            password=hashed_password, 
            license_number=data.get('license_number'), 
            national_id=data.get('national_id'), 
            clinic=data.get('clinic'), 
            specialization=data.get('specialization')
        )

    db.session.add(user)
    db.session.commit()
    return jsonify({'message': f'{user_type} registered successfully!'}), 201

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

    return jsonify({'message': 'Invalid email or password'}), 401