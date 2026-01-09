import argparse
import os, json, uuid
import cv2
import numpy as np
from Ai.test_ai.embeddings import get_embedding

CAT_DB = "cat_db"
METADATA = f"{CAT_DB}/metadata.json"
IMAGES_DIR = f"{CAT_DB}/images"


def load_meta():
    if os.path.exists(METADATA):
        with open(METADATA, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {}


def save_meta(meta):
    with open(METADATA, 'w', encoding='utf-8') as f:
        json.dump(meta, f, ensure_ascii=False, indent=2)


def add_images(name, image_paths, set_profile=False):
    meta = load_meta()
    entry = meta.get(name)
    if entry is None:
        print(f"No cat named {name} in metadata. Create it first using register_cat.py")
        return

    img_folder = os.path.join(IMAGES_DIR, name)
    os.makedirs(img_folder, exist_ok=True)

    for p in image_paths:
        img = cv2.imread(p)
        if img is None:
            print(f"Failed to read {p}")
            continue
        try:
            img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        except Exception:
            img_rgb = img

        emb = get_embedding(img_rgb)
        emb_fn = f"{name}_{uuid.uuid4().hex}.npy"
        np.save(os.path.join(CAT_DB, emb_fn), emb)

        img_fn = f"{name}_{uuid.uuid4().hex}.jpg"
        img_path = os.path.join(img_folder, img_fn)
        cv2.imwrite(img_path, img)
        rel_img = os.path.relpath(img_path, start=CAT_DB)

        # ensure dict format
        if isinstance(entry, list):
            entry = {"embeddings": entry, "images": [], "profile": None}

        entry.setdefault("embeddings", []).append(emb_fn)
        entry.setdefault("images", []).append(rel_img)
        if set_profile:
            entry["profile"] = rel_img

    meta[name] = entry
    save_meta(meta)
    print(f"Added {len(image_paths)} images to {name}")


def set_profile(name, image_path):
    meta = load_meta()
    entry = meta.get(name)
    if entry is None:
        print(f"No cat named {name} in metadata.")
        return

    img = cv2.imread(image_path)
    if img is None:
        print(f"Failed to read {image_path}")
        return

    img_folder = os.path.join(IMAGES_DIR, name)
    os.makedirs(img_folder, exist_ok=True)
    img_fn = f"{name}_profile_{uuid.uuid4().hex}.jpg"
    img_path = os.path.join(img_folder, img_fn)
    cv2.imwrite(img_path, img)
    rel_img = os.path.relpath(img_path, start=CAT_DB)

    if isinstance(entry, list):
        entry = {"embeddings": entry, "images": [], "profile": None}

    entry["profile"] = rel_img
    entry.setdefault("images", []).append(rel_img)
    meta[name] = entry
    save_meta(meta)
    print(f"Set profile for {name} -> {rel_img}")


def main():
    parser = argparse.ArgumentParser(description="Update cat metadata and images")
    parser.add_argument('--name', required=True, help='Cat name')
    parser.add_argument('--add-images', nargs='+', help='Image files to add for training')
    parser.add_argument('--set-profile', help='Set profile image from file')
    args = parser.parse_args()

    if args.add_images:
        add_images(args.name, args.add_images, set_profile=False)
    if args.set_profile:
        set_profile(args.name, args.set_profile)


if __name__ == '__main__':
    main()
