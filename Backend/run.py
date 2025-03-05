from flask import Flask, jsonify, request
from flask_cors import CORS
import mysql.connector

app = Flask(__name__)
CORS(app)

db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="arish",
    database="vetconnect_db"
)
cursor = db.cursor()

@app.route('/')
def home():
    return jsonify({"message": "VetConnect API is running!"})

if __name__ == '__main__':
    app.run(debug=True)
