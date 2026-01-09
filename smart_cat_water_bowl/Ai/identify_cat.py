# identify_cat.py
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity

IDENTITY_THRESHOLD = 0.80


def identify_cat(query_emb, cat_bank):
    """
    cat_bank = {
        cat_uid: [emb1, emb2, ...]
    }
    return: (cat_uid or None, best_score)
    """

    best_score = 0.0
    best_cat = None

    for cat_uid, emb_list in cat_bank.items():
        if len(emb_list) == 0:
            continue

        sims = cosine_similarity(
            [query_emb],
            emb_list
        )[0]

        score = float(np.max(sims))  # 🔥 Metric logic

        if score > best_score:
            best_score = score
            best_cat = cat_uid

    if best_score >= IDENTITY_THRESHOLD:
        return best_cat, best_score

    return None, best_score
