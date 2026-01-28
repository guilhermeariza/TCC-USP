FROM alpine:latest

# Install build essentials (gcc, make, musl-dev)
RUN apk add --no-cache build-base

# Create app directory
WORKDIR /app

# Copy source code
COPY src/* /app/

# Build
RUN gcc -O3 -o benchmark main.c btree.c lsm.c

# Run
CMD ["./benchmark"]
