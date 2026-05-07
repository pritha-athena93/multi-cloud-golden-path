from fastapi import FastAPI
from starlette.responses import Response

app = FastAPI()


@app.get("/")
def root():
    return Response("Congratulations! Your infra is now up and running! Happy Coding!", media_type="text/plain")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
