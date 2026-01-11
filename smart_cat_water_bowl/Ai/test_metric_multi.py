import os
import cv2
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
from embeddings import get_embedding

# ================= CONFIG =================
CATS_DIR = "cats"     # โฟลเดอร์รวมแมว
QUERY_IMG = "query/test.jpg"
THRESHOLD = 0.78
# =========================================


def load_cat_bank(cat_root):
    """
    return:
    {
        cat_name: [emb1, emb2, ...]
    }
    """
    bank = {}

    for cat_name in os.listdir(cat_root):
        cat_path = os.path.join(cat_root, cat_name)
        if not os.path.isdir(cat_path):
            continue

        embs = []
        for fn in os.listdir(cat_path):
            if fn.lower().endswith((".jpg", ".png")):
                img = cv2.imread(os.path.join(cat_path, fn))
                if img is None:
                    continue
                rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
                embs.append(get_embedding(rgb))

        if embs:
            bank[cat_name] = embs
            print(f"📦 Loaded {len(embs)} images for {cat_name}")

    return bank


def identify(query_emb, bank):
    results = {}

    for cat, emb_list in bank.items():
        sims = cosine_similarity([query_emb], emb_list)[0]
        results[cat] = {
            "max": float(sims.max()),
            "mean": float(sims.mean())
        }

    return results


# ================= RUN =================
if __name__ == "__main__":
    bank = load_cat_bank(CATS_DIR)

    img = cv2.imread(QUERY_IMG)
    if img is None:
        raise RuntimeError("❌ Cannot load query image")

    rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    query_emb = get_embedding(rgb)

    scores = identify(query_emb, bank)

    print("\n🔍 RESULT")
    print("=" * 40)

    sorted_scores = sorted(
        scores.items(),
        key=lambda x: x[1]["max"],
        reverse=True
    )

    for cat, s in sorted_scores:
        mark = "✅" if s["max"] >= THRESHOLD else "❌"
        print(f"{mark} {cat:10s} | max={s['max']:.3f} | mean={s['mean']:.3f}")

    best_cat, best_score = sorted_scores[0]

    print("\n🏆 BEST MATCH")
    print(f"→ {best_cat} ({best_score['max']:.3f})")
