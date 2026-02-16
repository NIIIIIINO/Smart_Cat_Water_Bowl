# sync_from_storage.py  (READ-ONLY EMBEDDING SYNC)
print("SYNC FILE RUNNING")
import os
import json
import argparse
from collections import defaultdict

from firebase_init import bucket
from device import get_or_create_device_id

BASE_DB = "cat_db/users"


def sync_user_from_storage(user_id):
    """
    ดึง embedding จาก Firebase Storage:

        embeddings/v1/{user_id}/{catId}/*.npy

    → download local
    → rebuild metadata.json

    READ ONLY — ไม่เขียน Firestore / Storage
    """

    device_id = get_or_create_device_id()
    print(f"🔗 Sync EMBEDDINGS USER={user_id} DEVICE={device_id}")

    prefix = f"embeddings/v1/{user_id}/"
    blobs = bucket.list_blobs(prefix=prefix)

    emb_dir = os.path.join(
        BASE_DB, user_id, "devices", device_id, "embeddings"
    )
    os.makedirs(emb_dir, exist_ok=True)

    cat_map = defaultdict(list)
    count = 0

    for blob in blobs:
        if not blob.name.endswith(".npy"):
            continue

        # embeddings/v1/{uid}/{catId}/{file}.npy
        parts = blob.name.split("/")
        if len(parts) < 5:
            continue

        cat_id = parts[3]
        filename = parts[4]

        local_name = f"{cat_id}_{filename}"
        local_path = os.path.join(emb_dir, local_name)

        print("⬇️", blob.name)
        blob.download_to_filename(local_path)

        cat_map[cat_id].append(
            os.path.join("embeddings", local_name)
        )

        count += 1

    if count == 0:
        print("❌ No embeddings found in storage")
        return

    meta_dir = os.path.join(BASE_DB, user_id, "devices", device_id)
    os.makedirs(meta_dir, exist_ok=True)

    meta_path = os.path.join(meta_dir, "metadata.json")

    meta = {
        cat_id: {
            "name": cat_id,
            "embeddings": files
        }
        for cat_id, files in cat_map.items()
    }

    with open(meta_path, "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=2, ensure_ascii=False)

    print(f"✅ Downloaded {count} embeddings")
    print("✅ metadata.json rebuilt")
    print("🎯 Ready for detection")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--user", required=True)
    args = parser.parse_args()
    sync_user_from_storage(args.user)