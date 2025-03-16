from datetime import datetime, timedelta
import bcrypt
from firebase_admin import auth
from flask import Blueprint, jsonify, request
from flask_cors import CORS
from app.models import AnimalOwner, Veterinarian
from app.services.auth_service import register_user, login_user
from app import db
import secrets

auth_bp = Blueprint('auth_bp', __name__)
CORS(auth_bp)

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
