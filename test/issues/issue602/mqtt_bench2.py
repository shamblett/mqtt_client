import time
import paho.mqtt.client as mqtt

BROKER = 'localhost'
PORT = 1883
TOPIC = "benchmark/test"
EXPECTED_MESSAGES = 1000  # Should match publisher MESSAGE_COUNT

received_count = 0
total_bytes = 0
start_time = None
end_time = None

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("Connected to MQTT Broker")
        client.subscribe(TOPIC)
    else:
        print(f"Failed to connect, return code {rc}")

def on_message(client, userdata, msg):
    global received_count, total_bytes, start_time, end_time

    if received_count == 0:
        start_time = time.time()

    received_count += 1
    total_bytes += len(msg.payload)

    if received_count == EXPECTED_MESSAGES:
        end_time = time.time()
        client.loop_stop()

def benchmark_receiver():
    global start_time, end_time, received_count, total_bytes

    client = mqtt.Client()
    client.on_connect = on_connect
    client.on_message = on_message

    client.connect(BROKER, PORT, keepalive=60)
    client.loop_start()

    # Wait max 20 seconds to receive all messages
    timeout = time.time() + 20
    while received_count < EXPECTED_MESSAGES and time.time() < timeout:
        time.sleep(0.01)

    if received_count < EXPECTED_MESSAGES:
        print(f"Timeout! Received only {received_count} messages.")
    else:
        duration = end_time - start_time
        mb_received = total_bytes / (1024 * 1024)
        print(f"All {received_count} messages received.")
        print(f"Total receiving time: {duration:.4f} seconds")
        print(f"Receiving speed: {received_count / duration:.2f} messages/second")
        print(f"Data receiving throughput: {mb_received / duration:.4f} MB/s")

    client.disconnect()

if __name__ == "__main__":
    benchmark_receiver()
