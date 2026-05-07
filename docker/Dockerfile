# Stage 1: build dependencies
FROM python:3.12-slim AS builder
WORKDIR /app
COPY app/requirements.txt .
RUN pip install --no-cache-dir --target=/deps -r requirements.txt

# Stage 2: final image — distroless for minimal attack surface
FROM gcr.io/distroless/python3-debian12
WORKDIR /app
COPY --from=builder /deps /usr/local/lib/python3.12/site-packages
COPY app/ .
USER nonroot:nonroot
EXPOSE 8080
CMD ["main.py"]
