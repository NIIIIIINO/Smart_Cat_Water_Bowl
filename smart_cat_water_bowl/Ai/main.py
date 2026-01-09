import os
import cv2
import time
import numpy as np
from ultralytics import YOLO
from deep_sort_realtime.deepsort_tracker import DeepSort

# Local device helper
from embeddings import get_embedding
from identify_cat import identify_cat
from device import get_or_create_device_id

# ================= USER / DEVICE =================
USER_ID = "BPGAv5swzkeYcnFzMoussJlfVCD3"
# DEVICE_ID will be generated/persisted on first run if not set
DEVICE_ID = None
# ================================================

CAMERA_ID = 0
MODEL_PATH = "yolov8n.pt"

BASE_DB = "cat_db/users"


def load_device_cats(user_id, device_id):
    device_db = os.path.join(BASE_DB, user_id, "devices", device_id)
    metadata_path = os.path.join(device_db, "metadata.json")
    cat_embeddings = {}

    if not os.path.exists(metadata_path):
        print(f"⚠️ No device metadata for USER={user_id} DEVICE={device_id}")
        return cat_embeddings

    with open(metadata_path, "r", encoding="utf-8") as f:
        meta = json.load(f) if 'json' in globals() else __import__('json').load(f)

    for cat_uid, entry in meta.items():
        emb_files = entry.get("embeddings", []) if isinstance(entry, dict) else entry
        embs = []
        for fn in emb_files:
            path = os.path.join(device_db, fn)
            if os.path.exists(path):
                try:
                    embs.append(np.load(path))
                except Exception:
                    continue
        if embs:
            cat_embeddings[cat_uid] = np.mean(embs, axis=0)

    return cat_embeddings


# ---------- LOAD YOLO + TRACKER ----------
model = YOLO(MODEL_PATH)
tracker = DeepSort(max_age=30)

# ---------- RESOLVE DEVICE ID + LOAD CAT EMBEDDINGS ----------
if DEVICE_ID is None:
    DEVICE_ID = get_or_create_device_id()

cat_embeddings = load_device_cats(USER_ID, DEVICE_ID)
print(f"📦 Loaded {len(cat_embeddings)} cats for USER={USER_ID} DEVICE={DEVICE_ID}")

# ---------- CAMERA ----------
cap = cv2.VideoCapture(CAMERA_ID)
if not cap.isOpened():
    raise RuntimeError("❌ Cannot open camera")

device_db = os.path.join(BASE_DB, USER_ID, "devices", DEVICE_ID)
camera_dir = os.path.join(device_db, "camera_images")
os.makedirs(camera_dir, exist_ok=True)

print(f"🚀 Cat AI started for USER={USER_ID} DEVICE={DEVICE_ID}")

# ---------- TRACK → ID LOCK ----------
track_identity = {}

# ================= MAIN LOOP =================
while True:
    ret, frame = cap.read()
    if not ret:
        break

    detections = []
    results = model(frame, conf=0.4, verbose=False)

    # -------- YOLO DETECTION --------
    for r in results:
        for box in r.boxes:
            cls = int(box.cls[0])
            if model.names[cls] != "cat":
                continue

            x1, y1, x2, y2 = map(int, box.xyxy[0])
            detections.append([
                [x1, y1, x2 - x1, y2 - y1],
                float(box.conf[0]),
                "cat"
            ])

    # -------- TRACKING --------
    tracks = tracker.update_tracks(detections, frame=frame)

    for track in tracks:
        if not track.is_confirmed():
            continue

        track_id = track.track_id

        l, t, w, h = map(int, track.to_ltrb())
        crop = frame[t:t+h, l:l+w]
        if crop.size == 0:
            continue

        # 🔒 identity lock
        if track_id in track_identity:
            cat_uid = track_identity[track_id]
            score = None
        else:
            crop_rgb = cv2.cvtColor(crop, cv2.COLOR_BGR2RGB)
            emb = get_embedding(crop_rgb)
            cat_uid = None
            score = None
            if cat_embeddings:
                cat_uid, score = identify_cat(emb, cat_embeddings)
            track_identity[track_id] = cat_uid

        # save camera crop
        ts = int(time.time() * 1000)
        crop_fn = f"crop_{track_id}_{ts}.jpg"
        try:
            cv2.imwrite(os.path.join(camera_dir, crop_fn), crop)
        except Exception:
            pass

        if cat_uid:
            label = cat_uid
            color = (0, 255, 0)
            # feeding event print
            print(f"🐱 USER={USER_ID} DEVICE={DEVICE_ID} CAT={cat_uid} (score={score:.2f})")
        else:
            label = "Unknown"
            color = (0, 0, 255)

        cv2.rectangle(frame, (l, t), (l+w, t+h), color, 2)
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

# ---------- CLEANUP ----------
cap.release()
cv2.destroyAllWindows()
