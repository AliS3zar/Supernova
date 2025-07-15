FROM alpine:latest

# Install necessary packages
RUN apk add --no-cache \
    curl \
    ca-certificates \
    openssl

# Download and install Hysteria
RUN curl -fsSL https://get.hy2.sh/ | sh

# Create directory for config
RUN mkdir -p /etc/hysteria

# Copy configuration file
COPY config.yaml /etc/hysteria/config.yaml

# Generate self-signed certificate (for testing - use proper certs in production)
RUN openssl req -x509 -nodes -newkey rsa:4096 -keyout /etc/hysteria/server.key -out /etc/hysteria/server.crt -days 365 -subj "/CN=hysteria"

# Expose port (Railway will handle port mapping)
EXPOSE 443

# Create a startup script to handle Railway's dynamic port
RUN echo '#!/bin/sh\n\
PORT=${PORT:-443}\n\
sed -i "s/:443/:$PORT/g" /etc/hysteria/config.yaml\n\
exec hysteria server -c /etc/hysteria/config.yaml' > /start.sh && \
chmod +x /start.sh

# Run Hysteria with dynamic port
CMD ["/start.sh"]
