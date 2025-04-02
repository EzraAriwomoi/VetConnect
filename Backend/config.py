from flask import Flask
from flask_jwt_extended import JWTManager
from dotenv import load_dotenv
import os

load_dotenv()

class Config:
    SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URL', 'mysql+pymysql://root:arish@localhost/vetconnect_db')
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'your_very_secure_random_key')  # Ensure a secret key is set

# Create Flask app instance
app = Flask(__name__)
app.config.from_object(Config)  # Load configurations from Config class

# Setup JWT
jwt = JWTManager(app)

# Enable token blacklisting
app.config['JWT_BLACKLIST_ENABLED'] = True
app.config['JWT_BLACKLIST_TOKEN_CHECKS'] = ['access']
