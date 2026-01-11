# identify_cat.py
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity

IDENTITY_THRESHOLD = 0.78  # ใช้ค่าเดียวกับ test

def identify_cat(query_emb, cat_bank):
    """
    cat_bank = {
        cat_uid: [emb1, emb2, ...]
    }
    """
    best_score = 0.0
    best_cat = None

    for cat_uid, emb_list in cat_bank.items():
        if len(emb_list) == 0:
            continue

        sims = cosine_similarity([query_emb], emb_list)[0]
        score = float(np.max(sims))   # 🔥 metric learning

        if score > best_score:
            best_score = score
            best_cat = cat_uid

    if best_score >= IDENTITY_THRESHOLD:
        return best_cat, best_score

    return None, best_score
