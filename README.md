# ELK Honeypot Manager

## Overview

The **ELK Honeypot Manager** is a Docker-based solution that integrates the Elastic Stack (Elasticsearch, Logstash, Kibana) with dynamic honeypot deployment. The system allows for real-time capture, aggregation, and visualization of malicious activities on emulated vulnerable systems. A manager container acts as the central orchestrator, enabling SSH-triggered honeypot creation, with all logs forwarded to the ELK stack for analysis.

## Features

- **Elastic Stack Integration**: Centralized log collection, processing, and visualization using Elasticsearch, Logstash, and Kibana.
- **Dynamic Honeypot Deployment**: Honeypot containers are created dynamically upon SSH connections to the manager container, emulating real-world vulnerable systems.
- **Real-Time Logging**: Honeypots forward all captured logs directly to the ELK stack for live monitoring.
- **Customizable Dashboard**: A user-friendly Kibana dashboard visualizes logs, attack patterns, and activity statistics.
- **Automated Setup**: Scripts provided for streamlined configuration and deployment.
- **Realistic Environment**: Honeypot containers are pre-configured with common utilities and logging mechanisms to mimic legitimate systems.

## Architecture

1. **ELK Stack**:
   - **Elasticsearch**: Stores and indexes logs.
   - **Logstash**: Processes incoming logs from honeypots.
   - **Kibana**: Visualizes logs for analysis.
2. **Manager Container**:
   - Acts as the orchestrator for honeypot creation.
   - Runs a Python-based management script to handle log forwarding.
3. **Honeypot Containers**:
   - Emulates vulnerable systems with SSH access.
   - Captures commands, logs activities, and sends them to the ELK stack.

## Configuration Overview

### Docker Compose

The `docker-compose.yml` file defines the services, including:

- Elasticsearch, Logstash, and Kibana.
- The Manager container, which spawns honeypot containers dynamically.

### Manager Scripts

- **`manager.py`**: Handles log collection, communication with Logstash, and container management.
- **`spawn_honeypot.sh`**: Automates the creation of honeypot containers upon SSH connections.

### Honeypot Configuration

- Pre-installed with tools like SSH, Python, and logging utilities.
- Configured to forward logs to Logstash via Filebeat.
- Uses a Python-based logger (`logger.py`) for real-time activity capture.


