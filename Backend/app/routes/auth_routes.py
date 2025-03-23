from datetime import datetime, timedelta
import bcrypt
from firebase_admin import auth
from flask import Blueprint, jsonify, request, url_for
from flask_cors import CORS
from app.models import Animal, AnimalOwner, FavoriteVeterinarian, Veterinarian
from app.services.auth_service import register_user, login_user
from app import db
import secrets
import mysql.connector
import cloudinary
import cloudinary.uploader

auth_bp = Blueprint('auth_bp', __name__)
CORS(auth_bp)

def get_mysql_connection():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="arish",
        database="vetconnect_db"
    )

# Cloudinary Configuration
cloudinary.config(
    cloud_name="dhlrkwvoz",
    api_key="622252338293132",
    api_secret="sLoZrrBF3BQ6WJGwYV2YbXg6d38"
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


@auth_bp.route('/get_user', methods=['GET'])
def get_user():
    email = request.args.get('email')

    if not email:
        return jsonify({"error": "Missing email parameter"}), 400

    connection = get_mysql_connection()
    cursor = connection.cursor(dictionary=True)

    # Check if the email belongs to an animal owner
    cursor.execute("SELECT id, name FROM animal_owner WHERE email = %s", (email,))
    user = cursor.fetchone()

    # If not found in AnimalOwner, check Veterinarian table
    if not user:
        cursor.execute("SELECT id, name FROM Veterinarian WHERE email = %s", (email,))
        user = cursor.fetchone()

    cursor.close()
    connection.close()

    if user:
        print(f"User fetched for email {email}: {user}")  # Debugging line
        return jsonify(user), 200
    else:
        print(f"User not found for email: {email}")  # Debugging line
        return jsonify({"error": "User not found"}), 404


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
    species = data.get('species')
    gender = data.get('gender')
    color = data.get('color')
    date_of_birth_str = data.get('date_of_birth')
    image_url = data.get('image_url', '')

    # Check required fields
    if not owner_id or not name or not species or not gender or not color or not date_of_birth_str:
        return jsonify({"message": "Missing required fields", "success": False}), 400

    try:
        date_of_birth = datetime.strptime(date_of_birth_str, "%Y-%m-%d")
    except ValueError:
        return jsonify({"message": "Invalid date format. Use YYYY-MM-DD.", "success": False}), 400

    # Ensure the owner exists
    owner = AnimalOwner.query.get(owner_id)
    if not owner:
        return jsonify({"message": "Owner not found", "success": False}), 404

    try:
        new_animal = Animal(
            owner_id=owner_id,
            name=name,
            breed=breed,
            species=species,
            gender=gender,
            color=color,
            date_of_birth=date_of_birth,
            image_url=image_url
        )
        db.session.add(new_animal)
        db.session.commit()
        
        return jsonify({"message": "Animal registered successfully", "success": True, "animal_id": new_animal.id}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({"message": "An error occurred", "error": str(e), "success": False}), 500


@auth_bp.route('/upload_image', methods=['POST'])
def upload_image():
    if 'image' not in request.files:
        return jsonify({"error": "No image uploaded"}), 400

    image = request.files['image']
    
    try:
        upload_result = cloudinary.uploader.upload(image)
        image_url = upload_result["secure_url"]
        return jsonify({"image_url": image_url}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@auth_bp.route('/get_animals', methods=['GET'])
def get_animals():
    owner_id = request.args.get('owner_id', type=int)
    if owner_id is None:
        return jsonify({"error": "Missing owner_id"}), 400

    def calculate_age(dob):
        today = datetime.today()
        age_years = today.year - dob.year - ((today.month, today.day) < (dob.month, dob.day))
        age_months = (today.year - dob.year) * 12 + today.month - dob.month

        if age_years < 1:
            return f"{age_months} months"
        else:
            return f"{age_years} years"

    animals = Animal.query.filter_by(owner_id=owner_id).all()
    
    return jsonify([{
        "id": animal.id,
        "name": animal.name,
        "breed": animal.breed,
        "age": calculate_age(animal.date_of_birth) if animal.date_of_birth else "Unknown",
        "species": animal.species,
        "gender": animal.gender,
        "color": animal.color,
        "image_url": animal.image_url
    } for animal in animals]), 200


@auth_bp.route('/update_animal/<int:animal_id>', methods=['PUT'])
def update_animal(animal_id):
    data = request.json
    animal = Animal.query.get(animal_id)

    if not animal:
        return jsonify({"error": "Animal not found"}), 404

    date_of_birth_str = data.get("date_of_birth")
    if date_of_birth_str:
        try:
            animal.date_of_birth = datetime.strptime(date_of_birth_str, "%Y-%m-%d")
        except ValueError:
            return jsonify({"error": "Invalid date format. Use YYYY-MM-DD"}), 400

    animal.name = data.get("name", animal.name)
    animal.breed = data.get("breed", animal.breed)
    animal.species = data.get("species", animal.species)
    animal.gender = data.get("gender", animal.gender)
    animal.color = data.get("color", animal.color)
    animal.image_url = data.get("image_url", animal.image_url)

    try:
        db.session.commit()
        return jsonify({"message": "Animal updated successfully"}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500


@auth_bp.route('/delete_animal/<int:animal_id>', methods=['DELETE'])
def delete_animal(animal_id):
    animal = Animal.query.get(animal_id)

    if not animal:
        return jsonify({"error": "Animal not found"}), 404

    db.session.delete(animal)
    db.session.commit()
    return jsonify({"message": "Animal deleted successfully"}), 200


@auth_bp.route('/veterinarians', methods=['GET'])
def get_all_veterinarians():
    veterinarians = Veterinarian.query.all()
    vet_list = []
    
    for vet in veterinarians:
        profile_image = vet.profile_image
        # if not profile_image:
        #     profile_image = url_for('static', filename='user_guide1.png', _external=True)

        vet_list.append({
            "id": vet.id,
            "name": vet.name,
            "clinic": vet.clinic,
            "profile_image": profile_image
        })

    return jsonify({"veterinarians": vet_list})


@auth_bp.route('/add_favorite', methods=['POST'])
def add_favorite():
    try:
        data = request.get_json()
        owner_id = data.get('owner_id')
        veterinarian_id = data.get('veterinarian_id')

        if not owner_id or not veterinarian_id:
            return jsonify({"error": "Missing owner_id or veterinarian_id"}), 400

        connection = get_mysql_connection()
        cursor = connection.cursor()

        # Check if the veterinarian is already favorited
        cursor.execute(
            "SELECT * FROM favorite_veterinarian WHERE owner_id = %s AND veterinarian_id = %s",
            (owner_id, veterinarian_id),
        )
        existing_fav = cursor.fetchone()

        if existing_fav:
            return jsonify({"message": "Already bookmarked"}), 409

        cursor.execute(
            "INSERT INTO favorite_veterinarian (owner_id, veterinarian_id) VALUES (%s, %s)",
            (owner_id, veterinarian_id),
        )
        connection.commit()

        cursor.close()
        connection.close()

        return jsonify({"message": "Veterinarian bookmarked successfully"}), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    

@auth_bp.route('/remove_favorite', methods=['DELETE'])
def remove_favorite():
    try:
        data = request.get_json()
        owner_id = data.get("owner_id")
        veterinarian_id = data.get("veterinarian_id")

        if not owner_id or not veterinarian_id:
            return jsonify({"error": "Missing owner_id or veterinarian_id"}), 400

        connection = get_mysql_connection()
        cursor = connection.cursor()

        # Check if the favorite exists
        cursor.execute(
            "SELECT * FROM favorite_veterinarian WHERE owner_id = %s AND veterinarian_id = %s",
            (owner_id, veterinarian_id)
        )
        favorite = cursor.fetchone()

        if not favorite:
            cursor.close()
            connection.close()
            return jsonify({"error": "Favorite not found"}), 404

        # Delete the favorite record
        cursor.execute(
            "DELETE FROM favorite_veterinarian WHERE owner_id = %s AND veterinarian_id = %s",
            (owner_id, veterinarian_id)
        )
        connection.commit()

        cursor.close()
        connection.close()

        return jsonify({"message": "Favorite removed successfully"}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500



@auth_bp.route('/get_favorites', methods=['GET'])
def get_favorites():
    owner_id = request.args.get('owner_id', type=int)
    if not owner_id:
        return jsonify({"error": "Missing owner_id"}), 400

    connection = get_mysql_connection()
    cursor = connection.cursor(dictionary=True)

    query = """
    SELECT v.id, v.name, v.clinic, v.profile_image
    FROM favorite_veterinarian fv
    JOIN veterinarian v ON fv.veterinarian_id = v.id
    WHERE fv.owner_id = %s
    """
    cursor.execute(query, (owner_id,))
    favorites = cursor.fetchall()

    cursor.close()
    connection.close()

    return jsonify(favorites), 200

