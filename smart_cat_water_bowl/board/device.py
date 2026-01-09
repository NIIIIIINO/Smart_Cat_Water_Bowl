import os
import uuid

DEVICE_FILE = os.path.join(os.path.dirname(__file__), "device_id.txt")


def get_or_create_device_id():
    try:
        if os.path.exists(DEVICE_FILE):
            with open(DEVICE_FILE, "r", encoding="utf-8") as f:
                did = f.read().strip()
                if did:
                    return did

        did = f"RASPI_{uuid.uuid4().hex[:8]}"
        with open(DEVICE_FILE, "w", encoding="utf-8") as f:
            f.write(did)
        return did
    except Exception:
        return f"RASPI_{uuid.uuid4().hex[:8]}"


if __name__ == "__main__":
    print(get_or_create_device_id())
