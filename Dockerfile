FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV TZ=UTC

# ============================================================
# SYSTEM PACKAGES
# ============================================================

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    wget \
    git \
    sudo \
    unzip \
    zip \
    rsync \
    procps \
    iproute2 \
    iputils-ping \
    net-tools \
    bridge-utils \
    iptables \
    openssh-client \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential \
    pkg-config \
    libffi-dev \
    libssl-dev \
    libpq-dev \
    libmariadb-dev \
    lxc \
    lxc-utils \
    lxc-templates \
    lxcfs \
    uidmap \
    mariadb-client \
    redis-tools \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*


# ============================================================
# PYTHON LIBRARIES
# ============================================================

RUN python3 -m pip install --no-cache-dir \
    flask \
    flask-socketio \
    flask-login \
    docker \
    paramiko \
    python-dotenv \
    psutil \
    flask-limiter \
    pymysql \
    mysql-connector-python \
    psycopg2-binary \
    redis \
    sqlalchemy \
    requests \
    gunicorn \
    eventlet


# ============================================================
# HVM 5.1
# ============================================================

WORKDIR /root

RUN git clone \
    https://github.com/DreamHost2ws/HVM5.1.git \
    /root/hvm

WORKDIR /root/hvm

# Install HVM's own requirements if available
RUN if [ -f requirements.txt ]; then \
        python3 -m pip install --no-cache-dir -r requirements.txt; \
    fi


# ============================================================
# LXC DIRECTORIES
# ============================================================

RUN mkdir -p \
    /var/lib/lxc \
    /var/lib/lxd \
    /run/lxc


# ============================================================
# STARTUP SCRIPT
# ============================================================

RUN cat > /usr/local/bin/start-hvm.sh <<'EOF'
#!/bin/bash

set -e

echo "=============================================="
echo "          HVM 5.1 PANEL"
echo "=============================================="
echo "Starting HVM..."
echo

cd /root/hvm

# Show installed LXC version
echo "LXC:"
lxc-info --version 2>/dev/null || true

echo
echo "Python:"
python3 --version

echo
echo "Starting application..."
echo

if [ -f hvm-5.1.py ]; then
    exec python3 hvm-5.1.py
elif [ -f hvm.py ]; then
    exec python3 hvm.py
else
    echo "ERROR: HVM startup file was not found."
    echo
    echo "Files in /root/hvm:"
    ls -la
    exit 1
fi
EOF

RUN chmod +x /usr/local/bin/start-hvm.sh


# ============================================================
# RAILWAY PORT
# ============================================================

EXPOSE 8080


# ============================================================
# START
# ============================================================

CMD ["/usr/local/bin/start-hvm.sh"]
