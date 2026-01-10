# register_cat.py
import os
import json
import cv2
import numpy as np
from embeddings import get_embedding
from device import get_or_create_device_id

# โครงสร้างฐานข้อมูล local
# cat_db/
#   users/
#     {user_id}/
#       devices/
#         {device_id}/
#           embeddings/
#           training_images/
#           metadata.json

BASE_DB = "cat_db/users"


# ---------- utils ----------
def ensure_dir(path):
    os.makedirs(path, exist_ok=True)


def load_meta(path):
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    return {}


def save_meta(path, meta):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=2, ensure_ascii=False)


# ---------- CORE FUNCTION ----------
def register_cat(
    user_id: str,
    device_id: str,
    cat_id: str,
    image_paths: list,
    cat_name: str | None = None
):
    """
    🔥 ฟังก์ชันเดียวที่ AI ต้องใช้

    user_id   = Firebase Auth UID
    device_id = ID เครื่อง (auto จาก device.py)
    cat_id    = Firestore cat document ID (ใช้เป็น UID หลัก)
    image_paths = list path รูปที่ดึงมาจาก Firebase Storage
    cat_name  = (optional) ชื่อแมวจาก Firestore
    """

    # path หลัก
    device_db = os.path.join(BASE_DB, user_id, "devices", device_id)
    embeddings_dir = os.path.join(device_db, "embeddings")
    training_dir = os.path.join(device_db, "training_images")
    metadata_path = os.path.join(device_db, "metadata.json")

    ensure_dir(embeddings_dir)
    ensure_dir(training_dir)

    meta = load_meta(metadata_path)

    emb_files = []
    training_files = []
    profile_img = None

    for idx, img_path in enumerate(image_paths):
        img = cv2.imread(img_path)
        if img is None:
            print(f"❌ Cannot read image: {img_path}")
            continue

        rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        emb = get_embedding(rgb)

        # ----- save embedding -----
        emb_name = f"{cat_id}_{idx+1}.npy"
        np.save(
            os.path.join(embeddings_dir, emb_name),
            emb
        )
        emb_files.append(os.path.join("embeddings", emb_name))

        # ----- save training image -----
        img_name = f"{cat_id}_{idx+1}.jpg"
        cv2.imwrite(
            os.path.join(training_dir, img_name),
            img
        )
        training_files.append(os.path.join("training_images", img_name))

        # ----- profile image -----
        if idx == 0:
            profile_img = os.path.join(
                "training_images",
                f"{cat_id}_profile.jpg"
            )
            cv2.imwrite(
                os.path.join(device_db, profile_img),
                img
            )

    # ----- update metadata -----
    meta[cat_id] = {
        "name": cat_name or cat_id,
        "embeddings": emb_files,
        "training_images": training_files,
        "profile": profile_img
    }

    save_meta(metadata_path, meta)

    print(
        f"✅ Registered cat UID={cat_id} "
        f"(images={len(emb_files)}) "
        f"for USER={user_id} DEVICE={device_id}"
    )


# ---------- optional CLI (debug only) ----------
if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--user", required=True)
    parser.add_argument("--cat-id", required=True)
    parser.add_argument("images", nargs="+")
    parser.add_argument("--name", required=False)
    parser.add_argument("--device", required=False)
    args = parser.parse_args()

    device_id = args.device or get_or_create_device_id()

    register_cat(
        user_id=args.user,
        device_id=device_id,
        cat_id=args.cat_id,
        cat_name=args.name,
        image_paths=args.images
    )
