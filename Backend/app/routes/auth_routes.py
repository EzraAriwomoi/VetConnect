from datetime import datetime, timedelta
import bcrypt
from firebase_admin import auth
from flask import Blueprint, jsonify, request
from flask_cors import CORS
from app.models import Animal, AnimalOwner, Veterinarian
from app.services.auth_service import register_user, login_user
from app import db
import secrets
import mysql.connector

auth_bp = Blueprint('auth_bp', __name__)
CORS(auth_bp)

def get_mysql_connection():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="arish",
        database="vetconnect_db"
    )

@auth_bp.route('/register/animal_owner', methods=['POST', 'OPTIONS'])
def register_animal_owner():
    if request.method == 'OPTIONS':
        return _build_cors_preflight_response()

    data = request.get_json()
    response, status_code = register_user('animal_owner')

    if status_code == 201:
        try:
            user = auth.create_user(
                email=data['email'],
                password=data['password'],
                display_name=data['name']
            )
            print(f"Firebase user created: {user.uid}")
        except Exception as e:
            print(f"Error creating Firebase user: {e}")

    return response, status_code

@auth_bp.route('/register/veterinarian', methods=['POST', 'OPTIONS'])
def register_veterinarian():
    if request.method == 'OPTIONS':
        return _build_cors_preflight_response()

    data = request.get_json()
    response, status_code = register_user('veterinarian')

    if status_code == 201:
        try:
            user = auth.create_user(
                email=data['email'],
                password=data['password'],
                display_name=data['name']
            )
            print(f"Firebase user created: {user.uid}")
        except Exception as e:
            print(f"Error creating Firebase user: {e}")

    return response, status_code

@auth_bp.route('/get_veterinarians', methods=['GET'])
def get_veterinarians():
    try:
        connection = get_mysql_connection()
        cursor = connection.cursor(dictionary=True)

        query = "SELECT id, name, email, clinic, specialization FROM Veterinarian"
        cursor.execute(query)
        veterinarians = cursor.fetchall()

        cursor.close()
        connection.close()

        return jsonify(veterinarians), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@auth_bp.route('/get_vet_name', methods=['GET'])
def get_vet_name():
    vet_email = request.args.get('vet_id')
    conn = get_mysql_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("SELECT name FROM Veterinarian WHERE email = %s", (vet_email,))
    vet = cursor.fetchone()

    conn.close()

    if vet:
        return jsonify({"name": vet["name"]})
    else:
        return jsonify({"error": "Vet not found"}), 404


@auth_bp.route('/login', methods=['POST', 'OPTIONS'])
def login():
    if request.method == 'OPTIONS':
        return _build_cors_preflight_response()
    return login_user()

def _build_cors_preflight_response():
    response = jsonify({'message': 'CORS preflight success'})
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type, Authorization')
    return response

@auth_bp.route('/forgot_password', methods=['POST'])
def forgot_password():
    data = request.get_json()
    email = data.get('email')
    user = AnimalOwner.query.filter_by(email=email).first() or Veterinarian.query.filter_by(email=email).first()
    if not user:
        return jsonify({"message": "If this email is associated with an account, a reset link will be sent."}), 200
    reset_token = secrets.token_urlsafe(32)
    user.reset_token = reset_token
    user.reset_token_expiry = datetime.utcnow() + timedelta(minutes=30)
    db.session.commit()
    print(f"Reset link: http://192.168.1.100:8000/reset-password?token={reset_token}")
    try:
        auth.generate_password_reset_link(email)
        print("Firebase password reset link sent.")
    except Exception as e:
        print(f"Error sending Firebase password reset email: {e}")
    return jsonify({"message": "Password reset link sent! Check your email."}), 200

@auth_bp.route('/reset_password', methods=['POST'])
def reset_password():
    data = request.get_json()
    token = data.get('token')
    new_password = data.get('new_password')
    user = AnimalOwner.query.filter_by(reset_token=token).first()
    if not user:
        user = Veterinarian.query.filter_by(reset_token=token).first()
    if not user:
        return jsonify({"message": "Invalid token"}), 400
    if user.reset_token_expiry and datetime.utcnow() > user.reset_token_expiry:
        return jsonify({"message": "Reset token has expired"}), 400
    hashed_password = bcrypt.hashpw(new_password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
    user.password = hashed_password
    user.reset_token = None
    user.reset_token_expiry = None
    db.session.commit()
    try:
        firebase_user = auth.get_user_by_email(user.email)
        auth.update_user(firebase_user.uid, password=new_password)
        print("Firebase password updated.")
    except Exception as e:
        print(f"Error updating Firebase password: {e}")
    return jsonify({"message": "Password reset successful!"}), 200

@auth_bp.route('/register_animal', methods=['POST'])
def register_animal():
    data = request.json
    owner_id = data.get('owner_id')
    name = data.get('name')
    breed = data.get('breed')
    age = data.get('age')
    species = data.get('species')
    image_url = data.get('image_url', '')

    # Check for missing required fields
    if not owner_id or not name or not species or age is None:
        return jsonify({"message": "Missing required fields", "success": False}), 400

    # Validate age
    if not isinstance(age, int) or age < 0:
        return jsonify({"message": "Invalid age value", "success": False}), 400

    # Ensure the owner exists
    owner = AnimalOwner.query.get(owner_id)
    if not owner:
        return jsonify({"message": "Owner not found", "success": False}), 404

    try:
        new_animal = Animal(owner_id=owner_id, name=name, breed=breed, age=age, species=species, image_url=image_url)
        db.session.add(new_animal)
        db.session.commit()
        
        return jsonify({"message": "Animal registered successfully", "success": True, "animal_id": new_animal.id}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({"message": "An error occurred", "error": str(e), "success": False}), 500

@auth_bp.route('/get_animals', methods=['GET'])
def get_animals():
    owner_id = request.args.get('owner_id', type=int)
    if owner_id is None:
        return jsonify({"error": "Missing owner_id"}), 400

    animals = Animal.query.filter_by(owner_id=owner_id).all()
    return jsonify([{
        "id": animal.id,
        "name": animal.name,
        "breed": animal.breed,
        "age": animal.age,
        "species": animal.species,
        "image_url": animal.image_url
    } for animal in animals]), 200

@auth_bp.route('/update_animal/<int:animal_id>', methods=['PUT'])
def update_animal(animal_id):
    data = request.json
    animal = Animal.query.get(animal_id)

    if not animal:
        return jsonify({"error": "Animal not found"}), 404

    animal.name = data.get('name', animal.name)
    animal.breed = data.get('breed', animal.breed)
    animal.age = data.get('age', animal.age)
    animal.species = data.get('species', animal.species)
    animal.image_url = data.get('image_url', animal.image_url)

    db.session.commit()
    return jsonify({"message": "Animal updated successfully"}), 200

@auth_bp.route('/delete_animal/<int:animal_id>', methods=['DELETE'])
def delete_animal(animal_id):
    animal = Animal.query.get(animal_id)

    if not animal:
        return jsonify({"error": "Animal not found"}), 404

    db.session.delete(animal)
    db.session.commit()
    return jsonify({"message": "Animal deleted successfully"}), 200