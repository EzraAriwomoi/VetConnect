from datetime import datetime, timedelta
import bcrypt
from firebase_admin import auth
from flask import Blueprint, jsonify, request, url_for
from flask_cors import CORS
from app.models import Animal, AnimalOwner, Appointment, FavoriteVeterinarian, Review, Veterinarian
from app.services.auth_service import register_user, login_user
from app import db
import secrets
import mysql.connector
import pytz
from pytz import timezone
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

LOCAL_TZ = timezone("Africa/Nairobi")

def utc_to_local(utc_dt):
    return utc_dt.replace(tzinfo=pytz.utc).astimezone(LOCAL_TZ)


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
    vet_id = request.args.get('vet_id', type=int)
    if not vet_id:
        return jsonify({"error": "Missing vet_id"}), 400

    conn = get_mysql_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("SELECT id, name, specialization FROM Veterinarian WHERE id = %s", (vet_id,))
    vet = cursor.fetchone()
    conn.close()

    print("Fetched vet:", vet)

    if vet:
        return jsonify({
            "id": vet["id"],
            "name": vet["name"],
            "specialization": vet["specialization"].split(",") if vet["specialization"] else []
        })
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
    cursor.execute("SELECT id, name, 'animal_owner' AS user_type FROM animal_owner WHERE email = %s", (email,))
    user = cursor.fetchone()

    # If not found in AnimalOwner, check Veterinarian table
    if not user:
        cursor.execute("SELECT id, name, clinic, specialization, 'veterinarian' AS user_type FROM Veterinarian WHERE email = %s", (email,))
        user = cursor.fetchone()

    cursor.close()
    connection.close()

    if user:
        return jsonify(user), 200
    else:
        return jsonify({"error": "User not found"}), 404


@auth_bp.route('/forgot_password', methods=['POST'])
def forgot_password():
    data = request.get_json()
    email = data.get('email')
    user = AnimalOwner.query.filter_by(email=email).first() or Veterinarian.query.filter_by(email=email).first()
    if not user:
        return jsonify({"message": "Email is not registered"}), 200
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


# Registration of animals
@auth_bp.route('/register_animal', methods=['POST'])
def register_animal():
    data = request.json
    owner_id = data.get('owner_id') # Foreign key to AnimalOwner
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

@auth_bp.route('/get_specific_animal', methods=['GET'])
def get_specific_animal():
    animal_id = request.args.get('animal_id', type=int)
    if animal_id is None:
        return jsonify({"error": "Missing animal_id"}), 400

    animal = Animal.query.get(animal_id)
    if not animal:
        return jsonify({"error": "Animal not found"}), 404

    return jsonify({
        "name": animal.name,
        "date_of_birth": animal.date_of_birth.strftime("%Y-%m-%d"),
        "breed": animal.breed,
        "color": animal.color,
        "gender": animal.gender,
        "species": animal.species
    }), 200


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
            return jsonify({"error": "Favorite not found"}), 4042

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


@auth_bp.route('/book_appointment', methods=['POST'])
def book_appointment():
    data = request.get_json()
    owner_id = data.get("owner_id") # Foreign key to AnimalOwner
    animal_id = data.get("animal_id") # Foreign key to Animal
    veterinarian_id = data.get("veterinarian_id") # Foreign key to Veterinarian
    date = data.get("date")
    time = data.get("time")
    appointment_type = data.get("appointment_type")

    if not owner_id or not veterinarian_id or not animal_id or not date or not time or not appointment_type:
        return jsonify({"error": "Missing required fields"}), 400

    animal = Animal.query.get(animal_id)
    if not animal:
        return jsonify({"error": "Animal not found"}), 404
    try:
        new_appointment = Appointment(
            owner_id=owner_id,
            animal_id=animal_id,
            veterinarian_id=veterinarian_id,
            date=datetime.strptime(date, "%Y-%m-%d"),
            time=time,
            appointment_type=appointment_type,
            status="Pending", # Default status
            notes="",
            prescription=""
        )
        db.session.add(new_appointment)
        db.session.commit() # Commit the new appointment to the database
        return jsonify({
            "message": "Appointment booked successfully and is now Pending.",
            "appointment_id": new_appointment.id
        }), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500


@auth_bp.route('/get_appointments', methods=['GET'])
def get_appointments():
    animal_id = request.args.get('animal_id', type=int)
    if animal_id is None:
        return jsonify({"error": "Missing animal_id"}), 400

    appointments = Appointment.query.filter_by(animal_id=animal_id).all()

    return jsonify([
        {
            "id": appointment.id,
            "date": appointment.date.strftime("%Y-%m-%d"),
            "time": appointment.time,
            "vet_name": appointment.veterinarian.name,
            "appointment_type": appointment.appointment_type,
            "status": appointment.status,
            "profile_image": appointment.veterinarian.profile_image
        }
        for appointment in appointments
    ]), 200


@auth_bp.route('/get_vet_appointments', methods=['GET'])
def get_vet_appointments():
    veterinarian_id = request.args.get('veterinarian_id', type=int)
    if not veterinarian_id:
        return jsonify({"error": "Missing veterinarian_id"}), 400

    try:
        appointments = (
            db.session.query(Appointment, Animal.name, Animal.species, Animal.image_url)
            .join(Animal, Appointment.animal_id == Animal.id)
            .filter(Appointment.veterinarian_id == veterinarian_id, Appointment.date >= datetime.today().date())
            .order_by(Appointment.date, Appointment.time)
            .all()
        )

        appointment_list = [
            {
                "id": appointment.Appointment.id,
                "owner_id": appointment.Appointment.owner_id,
                "animal_id": appointment.Appointment.animal_id,
                "veterinarian_id": appointment.Appointment.veterinarian_id,
                "date": appointment.Appointment.date.strftime("%Y-%m-%d"),
                "time": appointment.Appointment.time,
                "appointment_type": appointment.Appointment.appointment_type,
                "animal_name": appointment.name,
                "animal_species": appointment.species,
                "animal_image": appointment.image_url if appointment.image_url else "",
                "status": getattr(appointment.Appointment, 'status', 'Pending'),
                "notes": getattr(appointment.Appointment, 'notes', ''),
                "prescription": getattr(appointment.Appointment, 'prescription', '')
            }
            for appointment in appointments
        ]

        return jsonify(appointment_list), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@auth_bp.route('/update_appointment_status', methods=['POST'])
def update_appointment_status():
    data = request.get_json()
    appointment_id = data.get("appointment_id")
    new_status = data.get("status")

    if not appointment_id or not new_status:
        return jsonify({"error": "Missing appointment_id or status"}), 400

    valid_statuses = ["Pending", "Upcoming", "Completed", "Missed"]
    if new_status not in valid_statuses:
        return jsonify({"error": "Invalid status. Allowed: Pending, Upcoming, Completed, Missed"}), 400

    appointment = Appointment.query.get(appointment_id)
    if not appointment:
        return jsonify({"error": "Appointment not found"}), 404

    try:
        appointment.status = new_status
        db.session.commit()

        return jsonify({"message": f"Appointment status updated to {new_status}"}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500


@auth_bp.route('/update_appointment', methods=['POST'])
def update_appointment():
    data = request.get_json()
    appointment_id = data.get("appointment_id")
    status = data.get("status")
    notes = data.get("notes", "")
    prescription = data.get("prescription", "")

    if not appointment_id or not status:
        return jsonify({"error": "Missing required fields"}), 400

    try:
        appointment = Appointment.query.get(appointment_id)
        if not appointment:
            return jsonify({"error": "Appointment not found"}), 404

        appointment.status = status
        appointment.notes = notes
        appointment.prescription = prescription
        db.session.commit()

        return jsonify({"message": "Appointment updated successfully"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@auth_bp.route('/get_animal_appointment_history', methods=['GET'])
def get_animal_appointment_history():
    animal_id = request.args.get('animal_id', type=int)
    if not animal_id:
        return jsonify({"error": "Missing animal_id"}), 400

    try:
        # Get all appointments for this animal, ordered by date (newest first)
        appointments = (
            Appointment.query
            .filter_by(animal_id=animal_id)
            .order_by(Appointment.date.desc(), Appointment.time.desc())
            .all()
        )

        history = []
        for appointment in appointments:
            # Get veterinarian name
            vet = Veterinarian.query.get(appointment.veterinarian_id)
            vet_name = vet.name if vet else "Unknown Veterinarian"
            
            history.append({
                "id": appointment.id,
                "date": appointment.date.strftime("%Y-%m-%d"),
                "time": appointment.time,
                "appointment_type": appointment.appointment_type,
                "status": appointment.status,
                "notes": appointment.notes,
                "prescription": appointment.prescription,
                "veterinarian_name": vet_name,
                "created_at": appointment.created_at.strftime("%Y-%m-%d %H:%M:%S")
            })

        return jsonify(history), 200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@auth_bp.route('/submit_review', methods=['POST'])
def submit_review():
    data = request.get_json()
    veterinarian_id = data.get("veterinarian_id")
    owner_id = data.get("owner_id")
    review_text = data.get("review_text")

    if not veterinarian_id or not owner_id or not review_text:
        return jsonify({"error": "Missing required fields"}), 400

    try:
        new_review = Review(
            veterinarian_id=veterinarian_id,
            owner_id=owner_id,
            review_text=review_text
        )
        db.session.add(new_review)
        db.session.commit()
        return jsonify({"message": "Review submitted successfully"}), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500
    

@auth_bp.route('/get_reviews', methods=['GET'])
def get_reviews():
    vet_id = request.args.get('vet_id', type=int)
    if not vet_id:
        return jsonify({"error": "Missing vet_id"}), 400

    reviews = Review.query.filter_by(veterinarian_id=vet_id).all()
    review_list = []

    for review in reviews:
        owner = AnimalOwner.query.get(review.owner_id)
        owner_name = owner.name if owner else "Unknown"

        local_time = utc_to_local(review.created_at).strftime("%Y-%m-%d %H:%M:%S")

        review_list.append({
            "id": review.id,
            "veterinarian_id": review.veterinarian_id,
            "owner_id": review.owner_id,
            "user_name": owner_name,
            "review_text": review.review_text,
            "created_at": local_time
        })

    return jsonify(review_list), 200
