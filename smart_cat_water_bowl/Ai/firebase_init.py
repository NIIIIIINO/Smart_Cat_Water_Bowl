# firebase_init.py
import os
import firebase_admin
from firebase_admin import credentials, storage

AI_DIR = os.path.dirname(os.path.abspath(__file__))
BASE_DIR = os.path.dirname(AI_DIR)

cred_path = os.path.join(
    BASE_DIR,
    "secrets",
    "smart-cat-water-bowl-firebase-adminsdk-fbsvc-8ae7ca925f.json"
)

if not firebase_admin._apps:
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred, {
        "storageBucket": "smart-cat-water-bowl.firebasestorage.app"
    })

bucket = storage.bucket()
