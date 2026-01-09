import cv2
import os
import json
import time
import argparse
import numpy as np
from ultralytics import YOLO
from sklearn.metrics.pairwise import cosine_similarity
from embeddings import get_embedding
from device import get_or_create_device_id

MODEL_PATH = "yolov8n.pt"
SIM_THRESHOLD = 0.8

BASE_DB = "cat_db/users"

model = YOLO(MODEL_PATH)


# ---------- LOAD USER'S CAT EMBEDDINGS (UID = doc id) ----------
def load_user_cats(user_id, device_id=None):
    """Load cat embeddings for a user and optional device.
    If device_id provided, prefer device-specific metadata under
    cat_db/users/{user_id}/devices/{device_id}/metadata.json
    """
    base_user = os.path.join(BASE_DB, user_id)
    device_db = None
    if device_id:
        device_db = os.path.join(base_user, "devices", device_id)

    # prefer device metadata
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
                        continue

            if embs:
                cat_embeddings[cat_uid] = np.mean(embs, axis=0)

        # if we found cats in device metadata, stop searching
        if cat_embeddings:
            break

    return cat_embeddings


# ---------- IDENTIFY CAT ----------
def identify_cat_by_uid(emb, cat_embeddings):
    best_score, best_cat_uid = 0.0, None

    for cat_uid, ref_emb in cat_embeddings.items():
        score = cosine_similarity([emb], [ref_emb])[0][0]
        if score > best_score:
            best_score, best_cat_uid = score, cat_uid

    if best_score >= SIM_THRESHOLD:
        return best_cat_uid, best_score

    return None, best_score


# ---------- TEST IMAGE ----------
def test_image_for_user(user_id, image_path, device_id=None):
    # resolve device id if not provided (persisted per machine)
    if device_id is None:
        device_id = get_or_create_device_id()
    cat_embeddings = load_user_cats(user_id, device_id=device_id)

    if not cat_embeddings:
        print(f"❌ No cats registered for USER={user_id}")
        return

    print(f"✅ Loaded {len(cat_embeddings)} cats for USER={user_id}")

    img = cv2.imread(image_path)
    if img is None:
        print(f"❌ Cannot load image: {image_path}")
        return

    results = model(img, conf=0.4, verbose=False)
    found_cats = []
    # prepare camera_images folder when device given
    device_db = None
    if device_id:
        device_db = os.path.join(BASE_DB, user_id, "devices", device_id)
        cam_dir = os.path.join(device_db, "camera_images")
        os.makedirs(cam_dir, exist_ok=True)
    else:
        cam_dir = None

    for r in results:
        for box in r.boxes:
            if model.names[int(box.cls[0])] != "cat":
                continue

            x1, y1, x2, y2 = map(int, box.xyxy[0])
            crop = img[y1:y2, x1:x2]
            if crop.size == 0:
                continue

            rgb = cv2.cvtColor(crop, cv2.COLOR_BGR2RGB)
            emb = get_embedding(rgb)

            # save camera crop if device specified
            if cam_dir:
                ts = int(time.time() * 1000)
                crop_name = f"crop_{cat_uid if 'cat_uid' in locals() and cat_uid else 'unknown'}_{ts}.jpg"
                try:
                    cv2.imwrite(os.path.join(cam_dir, crop_name), crop)
                except Exception:
                    pass

            cat_uid, confidence = identify_cat_by_uid(emb, cat_embeddings)

            if cat_uid:
                label = f"{cat_uid} ({confidence:.2f})"
                color = (0, 255, 0)
                found_cats.append(cat_uid)
            else:
                label = "Unknown"
                color = (0, 0, 255)

            cv2.rectangle(img, (x1, y1), (x2, y2), color, 2)
            cv2.putText(
                img,
                label,
                (x1, y1 - 10),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.8,
                color,
                2
            )

    print("\n" + "=" * 50)
    print(f"🔍 Test Results for USER={user_id}")
    print("=" * 50)

    if found_cats:
        for uid in found_cats:
            print(f"🐱 Found cat UID: {uid}")
    else:
        print("❌ No registered cats found")

    print("=" * 50 + "\n")

    cv2.imshow(f"Test Image - USER={user_id}", img)
    cv2.waitKey(0)
    cv2.destroyAllWindows()


# ---------- RUN ----------
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--user", required=True, help="User ID")
    parser.add_argument("--image", required=True, help="Path to uploaded image")
    parser.add_argument("--device", required=False, help="Device ID to scope analysis")
    args = parser.parse_args()

    device = args.device or get_or_create_device_id()
    test_image_for_user(args.user, args.image, device_id=device)
