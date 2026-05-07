import os

VAULT_SECRET_PATH = "/vault/secrets/db.env"


def load_db_config() -> dict:
    config = {}
    with open(VAULT_SECRET_PATH) as f:
        for line in f:
            line = line.strip()
            if "=" in line and not line.startswith("#"):
                k, v = line.split("=", 1)
                config[k] = v
    return config
