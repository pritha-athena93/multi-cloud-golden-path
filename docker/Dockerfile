# Stage 1: build dependencies
FROM python:3.11-slim AS builder
WORKDIR /app
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Stage 2: final image — distroless for minimal attack surface
FROM gcr.io/distroless/python3-debian12
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
WORKDIR /app
COPY app/ .
USER nonroot:nonroot
EXPOSE 8080
CMD ["main.py"]
