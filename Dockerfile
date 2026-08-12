FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# ============================================================
# SYSTEM + HVM DEPENDENCIES
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
    nano \
    procps \
    iproute2 \
    iputils-ping \
    net-tools \
    bridge-utils \
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
    mariadb-client \
    redis-tools \
    postgresql-client \
    lxc \
    lxc-utils \
    lxc-templates \
    lxcfs \
    uidmap \
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

WORKDIR /opt

RUN git clone \
    https://github.com/DreamHost2ws/HVM5.1.git \
    hvm

WORKDIR /opt/hvm

RUN if [ -f requirements.txt ]; then \
        python3 -m pip install --no-cache-dir -r requirements.txt; \
    fi

# ============================================================
# RUNTIME DIRECTORIES
# ============================================================

RUN mkdir -p \
    /var/lib/lxc \
    /var/lib/lxd \
    /opt/hvm/data \
    /opt/hvm/logs

# ============================================================
# AUTOMATIC STARTUP
# ============================================================

RUN cat > /usr/local/bin/start-hvm.sh <<'EOF'
#!/bin/bash
set -e

echo "=========================================="
echo "           HVM 5.1 PANEL"
echo "=========================================="

cd /opt/hvm

echo "Python: $(python3 --version)"
echo "LXC: $(lxc-info --version 2>/dev/null || echo unavailable)"
echo "PORT: ${PORT:-8080}"

# Railway supplies PORT automatically.
# HVM itself must bind to 0.0.0.0:$PORT.

if [ -f hvm-5.1.py ]; then
    exec python3 hvm-5.1.py
fi

if [ -f hvm.py ]; then
    exec python3 hvm.py
fi

echo "ERROR: HVM startup file was not found."
ls -la
exit 1
EOF

RUN chmod +x /usr/local/bin/start-hvm.sh

# ============================================================
# RAILWAY
# ============================================================

EXPOSE 8080

CMD ["/usr/local/bin/start-hvm.sh"]
