# Simplified Dockerfile with better error handling

FROM maven:3.8-openjdk-11-slim

# Configure APT for better reliability
RUN echo 'Acquire::Retries "5";' > /etc/apt/apt.conf.d/80-retries && \
    echo 'Acquire::http::Timeout "60";' >> /etc/apt/apt.conf.d/80-retries

# Update package lists and install dependencies
# Split into smaller chunks for better error isolation
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libgflags-dev \
    libsnappy-dev \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
    zlib1g-dev \
    libbz2-dev \
    liblz4-dev \
    libzstd-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages
RUN pip3 install --no-cache-dir pandas matplotlib

# Create python symlink for YCSB compatibility
RUN ln -s /usr/bin/python3 /usr/bin/python

WORKDIR /app

# Copy application files
COPY scripts/ /app/scripts/
COPY configs/ /app/configs/
COPY analysis/ /app/analysis/

# Make scripts executable
RUN chmod +x /app/scripts/*.sh

# Build YCSB
RUN /app/scripts/build_ycsb.sh

# Set entrypoint
ENTRYPOINT ["/app/scripts/docker_entrypoint.sh"]
