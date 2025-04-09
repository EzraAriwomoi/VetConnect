from flask import Flask
from flask_jwt_extended import JWTManager
from dotenv import load_dotenv
import os

load_dotenv()

consumer_key = os.getenv('77oVKNqkC0FVX7DGhuHKVloRaXiquyGlga1UpzBbA7lKFKGi')
consumer_secret = os.getenv('BBxpqjzAyWrQHavD0vDMIz4UiyfrDCtpAwyAWXD1lenP0RodESTG91vwUNc5vrso')
shortcode = os.getenv('174379')
mpesa_callback_url = os.getenv('https://8ebd-102-0-11-2.ngrok-free.app/mpesa/callback')

# Safaricom API endpoints
auth_url = 'https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials'
payment_url = 'https://api.safaricom.co.ke/mpesa/stkpush/v1/processrequest'

class Config:
    SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URL', 'mysql+pymysql://root:arish@localhost/vetconnect_db')
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'your_very_secure_random_key')

app = Flask(__name__)
app.config.from_object(Config)

# Setup JWT
jwt = JWTManager(app)

# Enable token blacklisting
app.config['JWT_BLACKLIST_ENABLED'] = True
app.config['JWT_BLACKLIST_TOKEN_CHECKS'] = ['access']
