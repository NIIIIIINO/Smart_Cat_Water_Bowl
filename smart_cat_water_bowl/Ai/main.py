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

# ================= CONFIG =================
CAMERA_ID = 0
MODEL_PATH = "yolov8n.pt"
SIM_THRESHOLD = 0.8

BASE_DB = "cat_db/users"
RUNTIME_DB = "cat_db/runtime/current_user.json"
# ========================================


# ================= LOAD CURRENT USER (FROM LOGIN) =================
def get_current_user_id():
    if not os.path.exists(RUNTIME_DB):
        raise RuntimeError("❌ current_user.json not found (user not logged in)")

    with open(RUNTIME_DB, "r", encoding="utf-8") as f:
        data = json.load(f)

    user_id = data.get("user_id")
    if not user_id:
        raise RuntimeError("❌ user_id missing in current_user.json")

    return user_id


# ================= LOAD USER CATS =================
def load_user_cats(user_id, device_id=None):
    """
    Return: { cat_uid: [emb1, emb2, ...] }
    """
    base_user = os.path.join(BASE_DB, user_id)
    device_db = os.path.join(base_user, "devices", device_id) if device_id else None

    search_paths = []
    if device_db:
        search_paths.append(device_db)
    search_paths.append(base_user)

    cat_embeddings = {}

    for root in search_paths:
        metadata_path = os.path.join(root, "metadata.json")
        if not os.path.exists(metadata_path):
            continue

        with open(metadata_path, "r", encoding="utf-8") as f:
            meta = json.load(f)

        for cat_uid, entry in meta.items():
            emb_files = []
            if isinstance(entry, dict):
                emb_files = entry.get("embeddings", [])
            elif isinstance(entry, list):
                emb_files = entry

            embs = []
            for fn in emb_files:
                path = os.path.join(root, fn)
                if os.path.exists(path):
                    try:
                        embs.append(np.load(path))
                    except Exception:
                        pass

            if embs:
                cat_embeddings[cat_uid] = embs
                print(f"📦 Loaded {len(embs)} embeddings for {cat_uid}")

        if cat_embeddings:
            break

    return cat_embeddings


# ================= IDENTIFY CAT =================
def identify_cat(emb, cat_embeddings):
    best_score, best_cat_uid = 0.0, None

    for cat_uid, ref_emb_list in cat_embeddings.items():
        scores = cosine_similarity([emb], ref_emb_list)[0]
        score = float(np.max(scores))

        if score > best_score:
            best_score, best_cat_uid = score, cat_uid

    if best_score >= SIM_THRESHOLD:
        return best_cat_uid, best_score

    return None, best_score


# ================= ARG PARSE =================
parser = argparse.ArgumentParser()
parser.add_argument("--user", help="Force USER_ID for testing")
args = parser.parse_args()

if args.user:
    USER_ID = args.user
    print(f"🧪 TEST MODE: Using USER_ID from CLI = {USER_ID}")
else:
    USER_ID = get_current_user_id()
    print(f"👤 LOGIN MODE: USER_ID = {USER_ID}")

DEVICE_ID = get_or_create_device_id()
print(f"🧩 DEVICE={DEVICE_ID}")

# ================= LOAD DATA =================
cat_embeddings = load_user_cats(USER_ID, DEVICE_ID)
print(f"✅ Loaded {len(cat_embeddings)} cats")

# ================= INIT MODELS =================
model = YOLO(MODEL_PATH)
tracker = DeepSort(max_age=30)

# ================= CAMERA =================
cap = cv2.VideoCapture(CAMERA_ID)
if not cap.isOpened():
    raise RuntimeError("❌ Cannot open camera")

device_db = os.path.join(BASE_DB, USER_ID, "devices", DEVICE_ID)
camera_dir = os.path.join(device_db, "camera_images")
os.makedirs(camera_dir, exist_ok=True)

print("🚀 Cat AI started")

# ================= TRACK LOCK =================
track_identity = {}

# ================= MAIN LOOP =================
while True:
    ret, frame = cap.read()
    if not ret:
        break

    detections = []
    results = model(frame, conf=0.4, verbose=False)

    # ---------- YOLO ----------
    for r in results:
        for box in r.boxes:
            if model.names[int(box.cls[0])] != "cat":
                continue

            x1, y1, x2, y2 = map(int, box.xyxy[0])
            detections.append([
                [x1, y1, x2 - x1, y2 - y1],
                float(box.conf[0]),
                "cat"
            ])

    # ---------- TRACK ----------
    tracks = tracker.update_tracks(detections, frame=frame)

    for track in tracks:
        if not track.is_confirmed():
            continue

        track_id = track.track_id
        l, t, w, h = map(int, track.to_ltrb())

        crop = frame[t:t + h, l:l + w]
        if crop.size == 0:
            continue

        if track_id in track_identity:
            cat_uid, score = track_identity[track_id]
        else:
            rgb = cv2.cvtColor(crop, cv2.COLOR_BGR2RGB)
            emb = get_embedding(rgb)

            cat_uid, score = None, None
            if cat_embeddings:
                cat_uid, score = identify_cat(emb, cat_embeddings)

            track_identity[track_id] = (cat_uid, score)

        # ---------- SAVE ----------
        ts = int(time.time() * 1000)
        name = cat_uid if cat_uid else "unknown"
        cv2.imwrite(
            os.path.join(camera_dir, f"crop_{name}_{track_id}_{ts}.jpg"),
            crop
        )

        # ---------- DRAW ----------
        color = (0, 255, 0) if cat_uid else (0, 0, 255)
        label = cat_uid if cat_uid else "Unknown"

        cv2.rectangle(frame, (l, t), (l + w, t + h), color, 2)
        cv2.putText(
            frame,
            label,
            (l, max(t - 10, 20)),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.8,
            color,
            2
        )

    cv2.imshow("Cat AI System", frame)
    if cv2.waitKey(1) & 0xFF == ord("q"):
        break

# ================= CLEANUP =================
cap.release()
cv2.destroyAllWindows()
