FROM ubuntu:22.04

# Install required dependencies (add more as needed)
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Copy your script into the container
COPY supernova.sh /app/supernova.sh

WORKDIR /app

# Make your script executable
RUN chmod +x supernova.sh

# Set the default command (edit if your script needs arguments)
CMD ["bash", "supernova.sh"]
