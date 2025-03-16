from app import create_app
from flask_cors import CORS
import firebase_admin
from firebase_admin import credentials

app = create_app()
CORS(app, resources={r"/*": {"origins": "*"}})

# Initialized Firebase Admin SDK
cred = credentials.Certificate("C:\\Users\\Ariwomoi\\Documents\\App Development\\vetconnect\\Backend\\vetconnect-4da18-firebase-adminsdk-fbsvc-5d678635c3.json")
firebase_admin.initialize_app(cred)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
