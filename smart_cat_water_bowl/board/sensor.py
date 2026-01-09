"""
Sensor helpers for Raspberry Pi board.
Supports HC-SR04 ultrasonic sensor and a MockSensor for testing.
"""
import time
import logging

try:
    import RPi.GPIO as GPIO
    HAS_GPIO = True
except Exception:
    HAS_GPIO = False


class HCSR04Sensor:
    def __init__(self, trig_pin: int, echo_pin: int, timeout_s: float = 0.04):
        if not HAS_GPIO:
            raise RuntimeError("RPi.GPIO not available on this platform")
        self.trig = trig_pin
        self.echo = echo_pin
        self.timeout_s = timeout_s

        GPIO.setmode(GPIO.BCM)
        GPIO.setup(self.trig, GPIO.OUT)
        GPIO.setup(self.echo, GPIO.IN)
        GPIO.output(self.trig, False)
        time.sleep(0.05)

    def distance_cm(self) -> float:
        GPIO.output(self.trig, True)
        time.sleep(0.00001)
        GPIO.output(self.trig, False)

        start = time.time()
        while GPIO.input(self.echo) == 0:
            start = time.time()
            # guard
            if time.time() - start > self.timeout_s:
                raise TimeoutError("Timeout waiting for echo start")

        stop = time.time()
        while GPIO.input(self.echo) == 1:
            stop = time.time()
            if time.time() - start > 0.5:
                raise TimeoutError("Timeout waiting for echo end")

        elapsed = stop - start
        distance = (elapsed * 34300) / 2
        return distance

    def cleanup(self):
        try:
            GPIO.cleanup()
        except Exception:
            pass


class MockSensor:
    """Simple mock sensor for development or non-Pi platforms."""

    def __init__(self, fixed_distance_cm: float = 5.0):
        self.fixed = float(fixed_distance_cm)

    def distance_cm(self) -> float:
        return self.fixed

    def cleanup(self):
        return


def level_percent_from_distance(distance_cm: float, max_distance_cm: float = 20.0) -> float:
    """Convert measured distance (cm) to percentage full (0-100).

    Assumes distance 0 => 100% full, distance >= max_distance_cm => 0%.
    """
    d = float(distance_cm)
    m = float(max_distance_cm)
    if d <= 0:
        return 100.0
    if d >= m:
        return 0.0
    pct = (1.0 - (d / m)) * 100.0
    return round(pct, 2)