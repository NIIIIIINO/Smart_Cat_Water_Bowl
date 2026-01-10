# sync_from_storage.py
import os
import tempfile
import argparse
from firebase_init import bucket
from register_cat import register_cat
from device import get_or_create_device_id


def sync_user_from_storage(user_id):
    """
    🔥 ดึงแมวทั้งหมดของ user จาก Firebase Storage
    โครงสร้างที่คาดหวัง:
    cats/{user_id}/{cat_uid}/*.jpg
    """

    device_id = get_or_create_device_id()
    print(f"🔗 Sync USER={user_id} DEVICE={device_id}")

    prefix = f"cats/{user_id}/"
    blobs = bucket.list_blobs(prefix=prefix)

    cats = {}  # cat_uid -> [image paths]

    temp_dir = tempfile.mkdtemp()

    for blob in blobs:
        name = blob.name  # cats/{user}/{cat_uid}/xxx.jpg
        parts = name.split("/")

        if len(parts) < 4:
            continue

        _, uid, cat_uid, filename = parts

        if not filename.lower().endswith((".jpg", ".jpeg", ".png")):
            continue

        local_path = os.path.join(temp_dir, f"{cat_uid}_{filename}")
        blob.download_to_filename(local_path)

        cats.setdefault(cat_uid, []).append(local_path)

    if not cats:
        print("❌ No cats found in storage")
        return

    print(f"🐱 Found {len(cats)} cats in storage")

    for cat_uid, image_paths in cats.items():
        print(f"➡️ Register CAT={cat_uid} ({len(image_paths)} images)")
        register_cat(
            user_id=user_id,
            device_id=device_id,
            cat_id=cat_uid,          # 🔥 ใช้ Firestore UID ตรง ๆ
            image_paths=image_paths,
            cat_name=cat_uid         # optional
        )

    print("✅ Sync completed")


# ---------- CLI ----------
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--user", required=True, help="Firebase User UID")
    args = parser.parse_args()

    sync_user_from_storage(args.user)
