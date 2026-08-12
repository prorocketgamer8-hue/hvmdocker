FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV TZ=UTC

# ============================================================
# SYSTEM PACKAGES
# ============================================================

RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    ca-certificates \
    gnupg \
    lsb-release \
    sudo \
    nano \
    vim \
    unzip \
    zip \
    rsync \
    procps \
    iproute2 \
    iputils-ping \
    net-tools \
    bridge-utils \
    iptables \
    iptables-persistent \
    openssh-client \
    openssh-server \
    systemd \
    systemd-sysv \
    dbus \
    dbus-user-session \
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
    && rm -rf /var/lib/apt/lists/*


# ============================================================
# LXC
# ============================================================

RUN apt-get update && apt-get install -y \
    lxc \
    lxc-utils \
    lxc-templates \
    lxcfs \
    uidmap \
    apparmor \
    apparmor-utils \
    && rm -rf /var/lib/apt/lists/*


# ============================================================
# LXD
# ============================================================

RUN apt-get update && apt-get install -y \
    lxd \
    lxd-client \
    && rm -rf /var/lib/apt/lists/*


# ============================================================
# DATABASES
# ============================================================

# MariaDB
RUN apt-get update && apt-get install -y \
    mariadb-server \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Redis
RUN apt-get update && apt-get install -y \
    redis-server \
    && rm -rf /var/lib/apt/lists/*

# PostgreSQL
RUN apt-get update && apt-get install -y \
    postgresql \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*


# ============================================================
# PYTHON / PIP
# ============================================================

RUN mkdir -p /root/.config/pip

RUN printf '[global]\nbreak-system-packages = true\n' \
    > /root/.config/pip/pip.conf

RUN python3 -m pip install --no-cache-dir \
    flask \
    flask-socketio \
    flask-login \
    docker \
    paramiko \
    python-dotenv \
    psutil \
    flask-limiter


# ============================================================
# ADDITIONAL PYTHON / DATABASE LIBRARIES
# ============================================================

RUN python3 -m pip install --no-cache-dir \
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

# Install HVM's own requirements if present
RUN if [ -f requirements.txt ]; then \
        python3 -m pip install --no-cache-dir -r requirements.txt; \
    fi


# ============================================================
# CREATE REQUIRED DIRECTORIES
# ============================================================

RUN mkdir -p \
    /var/lib/lxc \
    /var/lib/lxd \
    /var/lib/mysql \
    /var/lib/redis \
    /var/lib/postgresql \
    /run/lxc \
    /run/lxd \
    /run/mysqld \
    /run/redis


# ============================================================
# AUTOMATIC STARTUP
# ============================================================

RUN cat > /usr/local/bin/start-all.sh <<'EOF'
#!/bin/bash

set -e

echo "=========================================="
echo "        HVM 5.1 ALL-IN-ONE SERVER"
echo "=========================================="

mkdir -p /run/dbus
mkdir -p /run/mysqld
mkdir -p /run/redis
mkdir -p /run/lxd

chown mysql:mysql /run/mysqld 2>/dev/null || true
chown redis:redis /run/redis 2>/dev/null || true


# ------------------------------------------------------------
# DBUS
# ------------------------------------------------------------

echo "[1/7] Starting DBus..."

dbus-daemon --system --fork 2>/dev/null || true


# ------------------------------------------------------------
# MARIADB
# ------------------------------------------------------------

echo "[2/7] Starting MariaDB..."

if command -v mariadbd >/dev/null 2>&1; then

    if [ ! -d /var/lib/mysql/mysql ]; then
        mariadb-install-db \
            --user=mysql \
            --datadir=/var/lib/mysql
    fi

    mariadbd \
        --user=mysql \
        --datadir=/var/lib/mysql \
        --bind-address=0.0.0.0 \
        >/var/log/mariadb.log 2>&1 &

fi


# ------------------------------------------------------------
# REDIS
# ------------------------------------------------------------

echo "[3/7] Starting Redis..."

if command -v redis-server >/dev/null 2>&1; then

    redis-server \
        --bind 0.0.0.0 \
        --protected-mode no \
        >/var/log/redis.log 2>&1 &

fi


# ------------------------------------------------------------
# POSTGRESQL
# ------------------------------------------------------------

echo "[4/7] Starting PostgreSQL..."

if command -v pg_ctlcluster >/dev/null 2>&1; then

    pg_ctlcluster --all start 2>/dev/null || true

fi


# ------------------------------------------------------------
# LXD
# ------------------------------------------------------------

echo "[5/7] Initializing LXD..."

if command -v lxd >/dev/null 2>&1; then

    if ! lxc info >/dev/null 2>&1; then

        cat <<'YAML' | lxd init --preseed || true
config: {}

networks:
- name: lxdbr0
  type: bridge
  config:
    ipv4.address: 10.20.0.1/24
    ipv4.nat: "true"
    ipv6.address: none

storage_pools:
- name: default
  driver: dir

profiles:
- name: default
  config: {}
  devices:
    eth0:
      name: eth0
      network: lxdbr0
      type: nic
    root:
      path: /
      pool: default
      type: disk

cluster: null
YAML

    fi

    echo "Starting LXD..."

    lxd >/var/log/lxd.log 2>&1 &

    sleep 5

fi


# ------------------------------------------------------------
# LXC CHECK
# ------------------------------------------------------------

echo "[6/7] Checking LXC..."

lxc-info --version 2>/dev/null || true
lxc-ls 2>/dev/null || true


# ------------------------------------------------------------
# HVM
# ------------------------------------------------------------

echo "[7/7] Starting HVM 5.1..."

cd /root/hvm

if [ -f hvm-5.1.py ]; then

    exec python3 hvm-5.1.py

elif [ -f hvm.py ]; then

    exec python3 hvm.py

else

    echo "ERROR: HVM startup file was not found."
    ls -la
    exit 1

fi
EOF

RUN chmod +x /usr/local/bin/start-all.sh


# ============================================================
# PORTS
# ============================================================

EXPOSE 80
EXPOSE 443
EXPOSE 3306
EXPOSE 5432
EXPOSE 6379


# ============================================================
# START EVERYTHING
# ============================================================

CMD ["/usr/local/bin/start-all.sh"]
