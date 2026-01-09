import os
import cv2
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
from embeddings import get_embedding

THRESHOLD = 0.83   # conservative


def load_cat_embeddings(cat_dir):
    embs = []
    for fn in os.listdir(cat_dir):
        if fn.lower().endswith((".jpg", ".png")):
            img = cv2.imread(os.path.join(cat_dir, fn))
            if img is None:
                continue
            rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
            embs.append(get_embedding(rgb))
    return np.array(embs)


cat_A = load_cat_embeddings("cat_A")
cat_B = load_cat_embeddings("cat_B")


def max_similarity(query_emb, bank_embs):
    sims = cosine_similarity([query_emb], bank_embs)[0]
    return sims.max(), sims


print("🔍 SAME CAT (Metric)")
for i, emb in enumerate(cat_A):
    score, _ = max_similarity(emb, cat_A)
    print(f"cat_A[{i}] → cat_A = {score:.3f}")

print("\n🔍 DIFFERENT CAT (Metric)")
for i, emb in enumerate(cat_A):
    score, _ = max_similarity(emb, cat_B)
    print(f"cat_A[{i}] → cat_B = {score:.3f}")
