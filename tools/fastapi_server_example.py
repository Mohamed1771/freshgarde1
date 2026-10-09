"""Reference FastAPI server matching the contract expected by FastApiInspectionService.

Replace `run_model_on_image` / `run_model_on_video` with calls to your real model.

    pip install fastapi uvicorn python-multipart
    uvicorn fastapi_server_example:app --host 0.0.0.0 --port 8000
"""

from fastapi import FastAPI, File, Form, UploadFile
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="FreshRoute AI inspection")

# Needed when the Flutter app runs in Chrome (different origin).
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

# Allowed maturity_stage values (must match MaturityStage.apiKey in Flutter):
# mature_green, breaker, turning, ripe, overripe, spoiled


def run_model_on_image(data: bytes, product_hint: str | None) -> dict:
    # TODO: decode the image and run your model here.
    return {
        "product": product_hint or "tomato",
        "maturity_stage": "turning",
        "confidence": 0.91,
        "quality_score": 86.0,
        "defects": [{"label": "bruise", "severity": 0.25, "area_pct": 2.5}],
        "recommendation": "Keep at 11.5-12 C and 90% RH.",
        "model_version": "my-model-1.0",
        "simulated": False,
    }


def run_model_on_video(data: bytes, product_hint: str | None) -> dict:
    # TODO: sample frames, run the model per frame and aggregate.
    return run_model_on_image(data, product_hint)


@app.post("/predict/image")
async def predict_image(file: UploadFile = File(...), product_hint: str | None = Form(None)):
    return run_model_on_image(await file.read(), product_hint)


@app.post("/predict/video")
async def predict_video(file: UploadFile = File(...), product_hint: str | None = Form(None)):
    return run_model_on_video(await file.read(), product_hint)
