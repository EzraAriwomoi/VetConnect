from flask import Blueprint, jsonify, request
from flask_cors import CORS
from app.models import AnimalOwner, Veterinarian, Animal, Appointment, Review
from app import db
import datetime
import secrets
import json
from sqlalchemy import desc, func

api_bp = Blueprint('api_bp', __name__)
CORS(api_bp)

# Helper function to convert database objects to JSON-serializable dictionaries
def to_dict(obj):
    if isinstance(obj, datetime.datetime):
        return obj.isoformat()
    elif isinstance(obj, datetime.date):
        return obj.isoformat()
    return str(obj)

# Authentication endpoints
@api_bp.route('/auth/login', methods=['POST'])
def login():
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

    if user and user.check_password(password):
        # Generate token
        token = secrets.token_hex(32)
        
        # Return user data and token
        return jsonify({
            'success': True,
            'token': token,
            'user': {
                'id': user.id,
                'name': user.name,
                'email': user.email,
                'user_type': user_type
            }
        }), 200
    
    return jsonify({
        'success': False,
        'message': 'Invalid credentials'
    }), 401

@api_bp.route('/users/me', methods=['GET'])
def get_current_user():
    # In a real implementation, you would get the user ID from the token
    # For now, we'll use a query parameter for testing
    user_id = request.args.get('user_id')
    user_type = request.args.get('user_type')
    
    if not user_id or not user_type:
        return jsonify({
            'success': False,
            'message': 'Missing user_id or user_type'
        }), 400
    
    if user_type == 'animal_owner':
        user = AnimalOwner.query.get(user_id)
    else:
        user = Veterinarian.query.get(user_id)
    
    if not user:
        return jsonify({
            'success': False,
            'message': 'User not found'
        }), 404
    
    # Return user data
    user_data = {
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'user_type': user_type
    }
    
    if user_type == 'animal_owner':
        user_data['location'] = user.location
        user_data['phone'] = user.phone
    else:
        user_data['clinic'] = user.clinic
        user_data['specialization'] = user.specialization
        user_data['profile_image'] = user.profile_image
    
    return jsonify({
        'success': True,
        'data': user_data
    }), 200

# Chat endpoints
@api_bp.route('/chats', methods=['GET'])
def get_chat_rooms():
    # In a real implementation, you would get the user ID from the token
    user_id = request.args.get('user_id')
    user_type = request.args.get('user_type')
    
    if not user_id or not user_type:
        return jsonify({
            'success': False,
            'message': 'Missing user_id or user_type'
        }), 400
    
    # For now, return mock data
    # In a real implementation, you would query your database
    chats = []
    
    # If user is an animal owner, get chats with vets
    if user_type == 'animal_owner':
        vets = Veterinarian.query.all()
        for vet in vets:
            # Create a chat ID by combining user IDs
            ids = sorted([int(user_id), vet.id])
            chat_id = f"{ids[0]}_{ids[1]}"
            
            chats.append({
                'id': chat_id,
                'other_user_id': str(vet.id),
                'other_user_name': vet.name,
                'last_message': 'No messages yet',
                'last_message_time': datetime.datetime.now().isoformat(),
                'unread_count': 0,
                'other_user_image_url': vet.profile_image
            })
    # If user is a vet, get chats with animal owners
    else:
        owners = AnimalOwner.query.all()
        for owner in owners:
            # Create a chat ID by combining user IDs
            ids = sorted([int(user_id), owner.id])
            chat_id = f"{ids[0]}_{ids[1]}"
            
            chats.append({
                'id': chat_id,
                'other_user_id': str(owner.id),
                'other_user_name': owner.name,
                'last_message': 'No messages yet',
                'last_message_time': datetime.datetime.now().isoformat(),
                'unread_count': 0,
                'other_user_image_url': None
            })
    
    return jsonify(chats), 200

@api_bp.route('/chats/<chat_id>/messages', methods=['GET'])
def get_messages(chat_id):
    # In a real implementation, you would query your database for messages
    # For now, return mock data
    messages = []
    
    # Parse the chat ID to get user IDs
    user_ids = chat_id.split('_')
    if len(user_ids) != 2:
        return jsonify({
            'success': False,
            'message': 'Invalid chat_id format'
        }), 400
    
    # Get the users
    user1 = AnimalOwner.query.get(user_ids[0]) or Veterinarian.query.get(user_ids[0])
    user2 = AnimalOwner.query.get(user_ids[1]) or Veterinarian.query.get(user_ids[1])
    
    if not user1 or not user2:
        return jsonify({
            'success': False,
            'message': 'One or both users not found'
        }), 404
    
    # Return empty list for now
    # In a real implementation, you would query your database for messages
    return jsonify(messages), 200

@api_bp.route('/chats/<chat_id>/messages', methods=['POST'])
def send_message(chat_id):
    data = request.get_json()
    content = data.get('content')
    
    if not content:
        return jsonify({
            'success': False,
            'message': 'Missing content'
        }), 400
    
    # In a real implementation, you would save the message to your database
    # For now, just return success
    return jsonify({
        'success': True,
        'message': 'Message sent'
    }), 201

@api_bp.route('/chats/<chat_id>/read', methods=['PUT'])
def mark_messages_as_read(chat_id):
    # In a real implementation, you would mark messages as read in your database
    # For now, just return success
    return jsonify({
        'success': True,
        'message': 'Messages marked as read'
    }), 200

@api_bp.route('/chats/<chat_id>/count', methods=['GET'])
def get_message_count(chat_id):
    # In a real implementation, you would count messages in your database
    # For now, return a mock count
    return jsonify({
        'count': 3
    }), 200

# Reviews endpoints
@api_bp.route('/vets/<vet_id>/reviews', methods=['GET'])
def get_vet_reviews(vet_id):
    # Get reviews for a specific vet
    reviews = Review.query.filter_by(veterinarian_id=vet_id).order_by(desc(Review.created_at)).all()
    
    review_list = []
    for review in reviews:
        owner = AnimalOwner.query.get(review.owner_id)
        
        review_data = {
            'id': str(review.id),
            'user_id': str(review.owner_id),
            'user_name': owner.name if owner else 'Unknown',
            'review_text': review.review_text,
            'rating': 5.0,  # Add rating field to your Review model
            'timestamp': review.created_at.isoformat(),
            'replies': []  # Add replies functionality to your database
        }
        
        review_list.append(review_data)
    
    return jsonify(review_list), 200

@api_bp.route('/vets/<vet_id>/reviews', methods=['POST'])
def add_review(vet_id):
    data = request.get_json()
    review_text = data.get('reviewText')
    rating = data.get('rating', 5.0)
    
    # In a real implementation, you would get the user ID from the token
    owner_id = request.args.get('user_id')
    
    if not owner_id or not review_text:
        return jsonify({
            'success': False,
            'message': 'Missing required fields'
        }), 400
    
    # Check if vet exists
    vet = Veterinarian.query.get(vet_id)
    if not vet:
        return jsonify({
            'success': False,
            'message': 'Veterinarian not found'
        }), 404
    
    # Create new review
    new_review = Review(
        veterinarian_id=vet_id,
        owner_id=owner_id,
        review_text=review_text
        # Add rating field to your Review model
    )
    
    db.session.add(new_review)
    db.session.commit()
    
    return jsonify({
        'success': True,
        'message': 'Review added successfully'
    }), 201

@api_bp.route('/vets/<vet_id>/reviews/<review_id>/replies', methods=['POST'])
def add_reply_to_review(vet_id, review_id):
    data = request.get_json()
    reply_text = data.get('replyText')
    
    # In a real implementation, you would get the user ID from the token
    user_id = request.args.get('user_id')
    
    if not user_id or not reply_text:
        return jsonify({
            'success': False,
            'message': 'Missing required fields'
        }), 400
    
    # Check if review exists
    review = Review.query.get(review_id)
    if not review or str(review.veterinarian_id) != vet_id:
        return jsonify({
            'success': False,
            'message': 'Review not found'
        }), 404
    
    # In a real implementation, you would add the reply to your database
    # For now, just return success
    return jsonify({
        'success': True,
        'message': 'Reply added successfully'
    }), 201

# Help desk endpoints
@api_bp.route('/helpdesk', methods=['GET'])
def get_helpdesk_posts():
    # In a real implementation, you would query your database for help desk posts
    # For now, return mock data
    posts = []
    
    # Return empty list for now
    # In a real implementation, you would query your database for help desk posts
    return jsonify(posts), 200

@api_bp.route('/helpdesk', methods=['POST'])
def add_helpdesk_post():
    data = request.get_json()
    title = data.get('title')
    content = data.get('content')
    animal_type = data.get('animalType')
    
    # In a real implementation, you would get the user ID from the token
    user_id = request.args.get('user_id')
    
    if not user_id or not title or not content or not animal_type:
        return jsonify({
            'success': False,
            'message': 'Missing required fields'
        }), 400
    
    # In a real implementation, you would save the post to your database
    # For now, just return success
    return jsonify({
        'success': True,
        'message': 'Post added successfully'
    }), 201

@api_bp.route('/helpdesk/<post_id>/comments', methods=['POST'])
def add_comment_to_helpdesk(post_id):
    data = request.get_json()
    comment = data.get('comment')
    
    # In a real implementation, you would get the user ID from the token
    user_id = request.args.get('user_id')
    
    if not user_id or not comment:
        return jsonify({
            'success': False,
            'message': 'Missing required fields'
        }), 400
    
    # In a real implementation, you would save the comment to your database
    # For now, just return success
    return jsonify({
        'success': True,
        'message': 'Comment added successfully'
    }), 201

# Notifications endpoints
@api_bp.route('/notifications', methods=['GET'])
def get_notifications():
    # In a real implementation, you would get the user ID from the token
    user_id = request.args.get('user_id')
    
    if not user_id:
        return jsonify({
            'success': False,
            'message': 'Missing user_id'
        }), 400
    
    # In a real implementation, you would query your database for notifications
    # For now, return mock data
    notifications = []
    
    # Return empty list for now
    # In a real implementation, you would query your database for notifications
    return jsonify(notifications), 200

@api_bp.route('/notifications/<notification_id>/read', methods=['PUT'])
def mark_notification_as_read(notification_id):
    # In a real implementation, you would mark the notification as read in your database
    # For now, just return success
    return jsonify({
        'success': True,
        'message': 'Notification marked as read'
    }), 200

# Vet profile endpoints
@api_bp.route('/vets/<vet_id>', methods=['GET'])
def get_vet_profile(vet_id):
    # Get vet profile
    vet = Veterinarian.query.get(vet_id)
    
    if not vet:
        return jsonify({
            'success': False,
            'message': 'Veterinarian not found'
        }), 404
    
    # Get average rating
    reviews = Review.query.filter_by(veterinarian_id=vet_id).all()
    review_count = len(reviews)
    
    # In a real implementation, you would calculate the average rating
    # For now, use a mock value
    average_rating = 4.5
    
    # Return vet profile data
    vet_data = {
        'id': vet.id,
        'full_name': vet.name,
        'email': vet.email,
        'clinic': vet.clinic,
        'specialization': vet.specialization,
        'profile_image_url': vet.profile_image,
        'average_rating': average_rating,
        'review_count': review_count,
        'bio': 'Professional veterinarian with years of experience.',  # Add bio field to your Veterinarian model
        'phone': '0712345678',  # Add phone field to your Veterinarian model
        'education': 'University of Veterinary Medicine',  # Add education field to your Veterinarian model
        'services': [
            {
                'name': 'General Checkup',
                'description': 'Complete health examination',
                'price': 1500
            },
            {
                'name': 'Vaccination',
                'description': 'Essential vaccines for your pet',
                'price': 2000
            }
        ]  # Add services field to your Veterinarian model
    }
    
    return jsonify({
        'success': True,
        'data': vet_data
    }), 200

@api_bp.route('/vets/search', methods=['GET'])
def search_vets():
    query = request.args.get('query', '')
    specialization = request.args.get('specialization', '')
    
    # Build the query
    vet_query = Veterinarian.query
    
    if query:
        vet_query = vet_query.filter(Veterinarian.name.ilike(f'%{query}%'))
    
    if specialization:
        vet_query = vet_query.filter(Veterinarian.specialization.ilike(f'%{specialization}%'))
    
    vets = vet_query.all()
    
    vet_list = []
    for vet in vets:
        vet_list.append({
            'id': vet.id,
            'name': vet.name,
            'clinic': vet.clinic,
            'specialization': vet.specialization,
            'profile_image': vet.profile_image
        })
    
    return jsonify(vet_list), 200

@api_bp.route('/vets/clinics', methods=['GET'])
def get_vet_clinics():
    # Get all vets with their clinic information
    vets = Veterinarian.query.all()
    
    clinics = []
    for vet in vets:
        # In a real implementation, you would have latitude and longitude stored
        # For now, use mock values
        clinics.append({
            'id': str(vet.id),
            'name': f"{vet.name}'s Clinic",
            'address': vet.clinic,
            'latitude': -1.286389 + (vet.id * 0.01),  # Mock values
            'longitude': 36.817223 + (vet.id * 0.01),  # Mock values
            'vet_name': vet.name
        })
    
    return jsonify(clinics), 200

@api_bp.route('/vets/<vet_id>/clinic', methods=['PUT'])
def update_clinic_location(vet_id):
    data = request.get_json()
    name = data.get('name')
    address = data.get('address')
    latitude = data.get('latitude')
    longitude = data.get('longitude')
    
    if not name or not address or latitude is None or longitude is None:
        return jsonify({
            'success': False,
            'message': 'Missing required fields'
        }), 400
    
    # Check if vet exists
    vet = Veterinarian.query.get(vet_id)
    if not vet:
        return jsonify({
            'success': False,
            'message': 'Veterinarian not found'
        }), 404
    
    # Update clinic information
    # In a real implementation, you would update the latitude and longitude
    vet.clinic = address
    db.session.commit()
    
    return jsonify({
        'success': True,
        'message': 'Clinic location updated successfully'
    }), 200

# Payment endpoints
@api_bp.route('/payments/mpesa', methods=['POST'])
def initiate_payment():
    data = request.get_json()
    phone_number = data.get('phoneNumber')
    amount = data.get('amount')
    description = data.get('description')
    
    if not phone_number or not amount or not description:
        return jsonify({
            'success': False,
            'message': 'Missing required fields'
        }), 400
    
    # In a real implementation, you would integrate with M-Pesa API
    # For now, just return success with a mock transaction ID
    transaction_id = secrets.token_hex(8)
    
    return jsonify({
        'success': True,
        'message': 'Payment initiated successfully',
        'transaction_id': transaction_id
    }), 200

@api_bp.route('/payments/status/<transaction_id>', methods=['GET'])
def check_payment_status(transaction_id):
    # In a real implementation, you would check the payment status with M-Pesa API
    # For now, just return success
    return jsonify({
        'success': True,
        'status': 'completed',
        'message': 'Payment completed successfully'
    }), 200

# Report endpoints
@api_bp.route('/reports/user', methods=['GET'])
def generate_user_report():
    # In a real implementation, you would get the user ID from the token
    user_id = request.args.get('user_id')
    
    if not user_id:
        return jsonify({
            'success': False,
            'message': 'Missing user_id'
        }), 400
    
    # In a real implementation, you would generate a PDF report
    # For now, just return a mock URL
    report_url = f"https://example.com/reports/user_{user_id}.pdf"
    
    return jsonify({
        'success': True,
        'reportUrl': report_url
    }), 200