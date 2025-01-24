import socket
import threading
import subprocess
import time
import logging
import json


LOGSTASH_HOST = 'logstash'
LOGSTASH_PORT = 5044
HOST = '0.0.0.0'
FLASK_PORT = 8080
LOG_PORT = 5000



print("Starting manager...")

def log_listener():
    # Create a socket for logging connections
    log_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    log_socket.bind((HOST, LOG_PORT))
    log_socket.listen(100)
    print(f"Manager listening for logs on port {LOG_PORT}...")
    while True:
        client_socket, client_address = log_socket.accept()
        # Start a new thread to handle each log connection
        threading.Thread(target=handle_log_connection, args=(client_socket, client_address)).start()

def handle_log_connection(client_socket, client_address):
    ip = client_address[0]
    print(f"Log connection from {ip}")
    with client_socket:
        while True:
            data = client_socket.recv(1024)
            if not data:
                break
            log_entry = data.decode().strip()
            # Send log to Logstash
            send_log_to_logstash(ip, log_entry)
            print(f"[{ip}] {log_entry}")

def send_log_to_logstash(ip, log_entry):
    log_data = {
        'ip': ip,
        'entry': log_entry,
        'timestamp': time.time()
    }
    try:
        logstash_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        logstash_socket.connect((LOGSTASH_HOST, LOGSTASH_PORT))
        logstash_socket.sendall((json.dumps(log_data) + '\n').encode())
        logstash_socket.close()
        print(f"Sent log to Logstash: {log_data}")
    except Exception as e:
        print(f"Failed to send log to Logstash: {e}")

def ensure_docker_ready():
    # Wait for Docker daemon to be accessible
    while True:
        try:
            subprocess.run(['docker', 'info'], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            print("Docker is ready")
            break
        except subprocess.CalledProcessError:
            print("Docker is not ready yet, waiting...")
            time.sleep(1)

def create_docker_network():
    # Ensure that the Docker network exists
    print('Making sure the Docker network exists')
    subprocess.run(['docker', 'network', 'create', 'honeypot_net'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


if __name__ == "__main__":
    # Ensure Docker is ready and network is created before starting log listener
    ensure_docker_ready()
    create_docker_network()

    # Start the log listener thread
    log_thread = threading.Thread(target=log_listener)
    log_thread.start()
