"""
Main runner for Raspberry Pi board.
Reads sensor, converts to percentage, and writes to Firestore periodically.
"""
import time
import argparse
import json
import logging
import signal
import sys
import os
from datetime import datetime

from sensor import HCSR04Sensor, MockSensor, level_percent_from_distance
from firestore_client import FirestoreClient


LOG = logging.getLogger("board_runner")

running = True


def handle_sigint(signum, frame):
    global running
    running = False


def load_config(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def main():
    parser = argparse.ArgumentParser(description="Raspberry Pi water sensor uploader")
    parser.add_argument("--config", default="board/config_example.json", help="Path to JSON config")
    parser.add_argument("--mock", action="store_true", help="Use mock sensor (no GPIO) ")
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

    cfg = load_config(args.config)
    device_id = cfg.get("device_id")
    # if no device id configured, generate and persist a per-board id
    if not device_id or device_id == "raspi-unknown":
        try:
            from device import get_or_create_device_id
            device_id = get_or_create_device_id()
        except Exception:
            device_id = f"raspi-{os.uname().nodename if hasattr(os, 'uname') else 'unknown'}"
    trig = cfg.get("trig_pin", 23)
    echo = cfg.get("echo_pin", 24)
    max_distance = cfg.get("max_distance_cm", 20)
    collection = cfg.get("collection", "water_levels")
    interval = cfg.get("interval", 60)

    sensor = None
    if args.mock or cfg.get("mock", False):
        LOG.info("Starting in mock sensor mode")
        sensor = MockSensor()
    else:
        try:
            sensor = HCSR04Sensor(trig, echo)
        except Exception as e:
            LOG.exception("Failed to initialize sensor: %s", e)
            LOG.info("Falling back to MockSensor")
            sensor = MockSensor()

    try:
        client = FirestoreClient(collection=collection)
    except Exception as e:
        LOG.exception("Failed to init Firestore client: %s", e)
        sys.exit(1)

    signal.signal(signal.SIGINT, handle_sigint)
    signal.signal(signal.SIGTERM, handle_sigint)

    LOG.info("Starting main loop (device=%s) interval=%s sec", device_id, interval)

    while running:
        try:
            dist = sensor.distance_cm()
            level = level_percent_from_distance(dist, max_distance)
            payload = {
                "device_id": device_id,
                "distance_cm": round(dist, 2),
                "level_pct": level,
                "local_ts": datetime.utcnow().isoformat() + "Z",
            }
            LOG.info("Measured dist=%.2f cm -> level=%.2f%%", dist, level)
            client.write_reading(payload)
        except Exception as e:
            LOG.exception("Error during measurement/upload: %s", e)
        # sleep with early exit checks
        for _ in range(int(interval)):
            if not running:
                break
            time.sleep(1)

    LOG.info("Shutting down...")
    try:
        sensor.cleanup()
    except Exception:
        pass
    try:
        client.close()
    except Exception:
        pass


if __name__ == "__main__":
    main()
