import argparse
import os
import json
import uuid
import cv2
import numpy as np
from embeddings import get_embedding
from device import get_or_create_device_id

# This script registers a cat for a given USER and DEVICE.
BASE_DB = "cat_db/users"


def ensure_dir(p):
    os.makedirs(p, exist_ok=True)


def load_meta(path):
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    return {}


def save_meta(path, meta):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=2, ensure_ascii=False)


def register_cat(user_id, device_id, cat_name, image_paths):
    user_db = os.path.join(BASE_DB, user_id)
    device_db = os.path.join(user_db, "devices", device_id)

    embeddings_dir = os.path.join(device_db, "embeddings")
    training_dir = os.path.join(device_db, "training_images")
    ensure_dir(embeddings_dir)
    ensure_dir(training_dir)

    metadata_path = os.path.join(device_db, "metadata.json")
    meta = load_meta(metadata_path)

    cat_id = f"cat_{uuid.uuid4().hex[:6]}"
    emb_files = []
    training_files = []
    profile_img = None

    for i, img_path in enumerate(image_paths):
        img = cv2.imread(img_path)
        if img is None:
            print(f"❌ Cannot read image: {img_path}")
            continue

        rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        emb = get_embedding(rgb)

        emb_name = f"{cat_id}_{i+1}.npy"
        emb_path = os.path.join(embeddings_dir, emb_name)
        np.save(emb_path, emb)
        emb_files.append(os.path.join("embeddings", emb_name))

        img_name = f"{cat_id}_{i+1}.jpg"
        img_path_out = os.path.join(training_dir, img_name)
        cv2.imwrite(img_path_out, img)
        training_files.append(os.path.join("training_images", img_name))

        if i == 0:
            profile_img = os.path.join("training_images", f"{cat_id}_profile.jpg")
            cv2.imwrite(os.path.join(device_db, profile_img), img)

    meta[cat_id] = {
        "name": cat_name,
        "embeddings": emb_files,
        "training_images": training_files,
        "profile": profile_img
    }

    save_meta(metadata_path, meta)
    print(f"✅ Registered cat '{cat_name}' for USER={user_id} DEVICE={device_id}")



def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--user", required=True, help="User ID")
    parser.add_argument("--device", required=False, help="Device ID (machine id). If omitted, auto-generated and persisted locally")
    parser.add_argument("--name", required=True, help="Cat name")
    parser.add_argument("images", nargs="+", help="Image files for training")
    args = parser.parse_args()

    device_id = args.device or get_or_create_device_id()
    register_cat(args.user, device_id, args.name, args.images)


if __name__ == "__main__":
    main()
