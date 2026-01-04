"""
Simple Firestore wrapper using Application Default Credentials.
Set the environment variable `GOOGLE_APPLICATION_CREDENTIALS` to
point to the service account JSON file on the Raspberry Pi.
"""
import os
import logging
from datetime import datetime

from google.cloud import firestore


class FirestoreClient:
    def __init__(self, collection: str = "water_levels"):
        sa = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
        if not sa:
            raise RuntimeError("Set GOOGLE_APPLICATION_CREDENTIALS to service account JSON path")
        self.db = firestore.Client()
        self.collection = collection

    def write_reading(self, payload: dict) -> None:
        """Add a new document with the provided payload.

        payload should be JSON-serializable. This method will add a `ts` field
        with server timestamp if not present.
        """
        if "ts" not in payload:
            payload["ts"] = firestore.SERVER_TIMESTAMP
        try:
            self.db.collection(self.collection).add(payload)
        except Exception as e:
            logging.exception("Failed to write to Firestore: %s", e)
            raise

    def close(self):
        # Firestore client has no explicit close; placeholder for symmetry.
        return
