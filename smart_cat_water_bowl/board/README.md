Board README
===========

This folder contains Raspberry Pi 3 code to read a water-level sensor (HC-SR04)
and upload readings to Firestore.

Files
- [board/config_example.json](board/config_example.json) : sample config
- [board/sensor.py](board/sensor.py) : HC-SR04 and mock sensor
- [board/firestore_client.py](board/firestore_client.py) : Firestore helper
- [board/board_runner.py](board/board_runner.py) : main loop
- [board/requirements.txt](board/requirements.txt) : Python deps

Quick setup
1. Copy your Firebase service-account JSON to the Pi (do NOT commit it to git).
2. On the Pi, set the env var:

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/home/pi/service-account.json"
```

On Windows PowerShell (for local testing):

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\path\to\service-account.json"
```

3. (Recommended) create a virtualenv and install deps:

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r board/requirements.txt
```

Note: `RPi.GPIO` usually requires running on a Raspberry Pi and may need `sudo apt install python3-rpi.gpio`

Run

```bash
# using the example config
python3 board/board_runner.py --config board/config_example.json

# or force mock mode (no GPIO) for development
python3 board/board_runner.py --config board/config_example.json --mock
```

Permissions
- GPIO access typically requires root. Use `sudo` if necessary.

Firestore
- The script uses Application Default Credentials from the service account JSON. Ensure the service account has Firestore write permissions.

Customization
- Edit `board/config_example.json` to change pins, collection name, interval, device_id, or mock mode.
