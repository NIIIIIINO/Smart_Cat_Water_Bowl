import os
import cv2
import time
import json
import argparse
import numpy as np
from ultralytics import YOLO
from deep_sort_realtime.deepsort_tracker import DeepSort
from sklearn.metrics.pairwise import cosine_similarity

from embeddings import get_embedding
from device import get_or_create_device_id

CAMERA_ID = 0
MODEL_PATH = "yolov8n.pt"
SIM_THRESHOLD = 0.71

BASE_DB = "cat_db/users"
RUNTIME_DB = "cat_db/runtime/current_user.json"


def get_current_user_id():
    if not os.path.exists(RUNTIME_DB):
        raise RuntimeError("❌ current_user.json not found")

    with open(RUNTIME_DB, "r", encoding="utf-8") as f:
        return json.load(f)["user_id"]


def load_user_cats(user_id, device_id):
    root = os.path.join(BASE_DB, user_id, "devices", device_id)
    meta_path = os.path.join(root, "metadata.json")

    if not os.path.exists(meta_path):
        print("❌ metadata.json not found — run sync first")
        return {}

    with open(meta_path, "r", encoding="utf-8") as f:
        meta = json.load(f)

    bank = {}

    for cat_uid, entry in meta.items():
        embs = []
        for fn in entry.get("embeddings", []):
            path = os.path.join(root, fn)
            if os.path.exists(path):
                embs.append(np.load(path))

        if embs:
            bank[cat_uid] = embs
            print(f"📦 Loaded {len(embs)} embeddings for {cat_uid}")

    return bank


def identify_cat(emb, bank):
    best_score = 0
    best_cat = None

    for cat_uid, ref_list in bank.items():
        s = cosine_similarity([emb], ref_list)[0].max()
        if s > best_score:
            best_score = float(s)
            best_cat = cat_uid

    if best_score >= SIM_THRESHOLD:
        return best_cat, best_score

    return None, best_score


# ---------- ARGS ----------
parser = argparse.ArgumentParser()
parser.add_argument("--user")
args = parser.parse_args()

USER_ID = args.user or get_current_user_id()
DEVICE_ID = get_or_create_device_id()

print("USER:", USER_ID)
print("DEVICE:", DEVICE_ID)

bank = load_user_cats(USER_ID, DEVICE_ID)
print("Cats loaded:", len(bank))

model = YOLO(MODEL_PATH)
tracker = DeepSort(max_age=30)

cap = cv2.VideoCapture(CAMERA_ID)
if not cap.isOpened():
    raise RuntimeError("Camera open failed")

track_identity = {}

print("🚀 AI running")

while True:
    ok, frame = cap.read()
    if not ok:
        break

    dets = []
    results = model(frame, conf=0.35, verbose=False)

    for r in results:
        for b in r.boxes:
            if model.names[int(b.cls[0])] != "cat":
                continue
            x1, y1, x2, y2 = map(int, b.xyxy[0])
            dets.append([[x1, y1, x2-x1, y2-y1], float(b.conf[0]), "cat"])

    tracks = tracker.update_tracks(dets, frame=frame)

    for tr in tracks:
        if not tr.is_confirmed():
            continue

        tid = tr.track_id
        l, t, w, h = map(int, tr.to_ltrb())
        crop = frame[t:t+h, l:l+w]
        if crop.size == 0:
            continue

        if tid not in track_identity:
            emb = get_embedding(cv2.cvtColor(crop, cv2.COLOR_BGR2RGB))
            track_identity[tid] = identify_cat(emb, bank)

        cat_uid, score = track_identity[tid]

        color = (0,255,0) if cat_uid else (0,0,255)
        label = cat_uid if cat_uid else "Unknown"

        cv2.rectangle(frame,(l,t),(l+w,t+h),color,2)
        cv2.putText(frame,label,(l,t-8),0,0.8,color,2)

    cv2.imshow("Cat AI", frame)
    if cv2.waitKey(1)==ord("q"):
        break

cap.release()
cv2.destroyAllWindows()