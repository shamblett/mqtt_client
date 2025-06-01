import json
import random
import time
from datetime import datetime, timedelta, timezone
import paho.mqtt.client as mqtt

# MQTT Configuration
MQTT_BROKER = "localhost"
MQTT_PORT = 1883
MQTT_TOPIC = "stations/tanks"

# Data generation
stations = 100
tanks_per_station = 1000
start_time = datetime.now(timezone.utc)

data = []

for station_id in range(1, stations + 1):
    for tank_id in range(1, tanks_per_station + 1):
        entry = {
            "topic": f"station{station_id}/tank{tank_id}",
            "value": random.randint(1000, 10000),
            "timestamp": (start_time + timedelta(seconds=(station_id * tank_id) % 300)).isoformat() + "Z"
        }
        data.append(entry)

# Convert to JSON string
json_payload = json.dumps(data)
payload_size = len(json_payload.encode("utf-8"))
print(f"Generated {len(data)} records, payload size: {payload_size / 1024:.2f} KB")

# MQTT Publish
client = mqtt.Client()
client.connect(MQTT_BROKER, MQTT_PORT, keepalive=60)
client.loop_start()
i=0
try:
    while True:
        start_time = time.time()
        timestamp = time.time()

        # Publish all topics as fast as possible (non-blocking like JS)
        client.publish("station1/all", payload=json_payload, qos=0, retain=False)

        # Calculate how long the publishing took
        publish_time = time.time() - start_time
        i=i+1
        print(i)
        time.sleep(0.1)

except KeyboardInterrupt:
    client.loop_stop()
    client.disconnect()

