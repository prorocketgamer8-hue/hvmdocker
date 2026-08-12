FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# ------------------------------------------------------------
# Base system
# ------------------------------------------------------------

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
    lxd \
    lxd-client \
    mariadb-client \
    redis-tools \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*


# ------------------------------------------------------------
# Python libraries
# ------------------------------------------------------------

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


# ------------------------------------------------------------
# HVM
# ------------------------------------------------------------

WORKDIR /root

RUN git clone \
    https://github.com/DreamHost2ws/HVM5.1.git \
    /root/hvm

WORKDIR /root/hvm

RUN if [ -f requirements.txt ]; then \
        pip3 install --no-cache-dir -r requirements.txt; \
    fi


# ------------------------------------------------------------
# HVM startup wrapper
# ------------------------------------------------------------

COPY start-hvm.sh /usr/local/bin/start-hvm.sh

RUN chmod +x /usr/local/bin/start-hvm.sh


# ------------------------------------------------------------
# Railway / web port
# ------------------------------------------------------------

EXPOSE 8080


# ------------------------------------------------------------
# Start HVM
# ------------------------------------------------------------

CMD ["/usr/local/bin/start-hvm.sh"]
