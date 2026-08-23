"""
FastAPI backend serving the house & road construction cost models.

Run locally:
    pip install -r requirements.txt
    uvicorn main:app --host 0.0.0.0 --port 8000 --reload

Test:
    curl -X POST http://localhost:8000/predict/house -H "Content-Type: application/json" \
      -d '{"built_up_area_sqft":1500,"floors":2,"quality_tier":"standard","city_tier":"tier2","structure_type":"RCC_frame","foundation_type":"normal"}'
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import Literal
import pandas as pd
import joblib
import os

app = FastAPI(title="Construction Cost Estimator API", version="1.0")

# Allow the Flutter app (web/mobile) to call this API.
# Lock this down to your actual app's origin(s) before going to production.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

MODEL_DIR = os.path.dirname(os.path.abspath(__file__))
house_model = joblib.load(os.path.join(MODEL_DIR, "models", "house_cost_model.joblib"))
road_model = joblib.load(os.path.join(MODEL_DIR, "models", "road_cost_model.joblib"))


# ---------- Request schemas ----------

class HouseRequest(BaseModel):
    built_up_area_sqft: float = Field(..., gt=0, description="Area per floor in sq ft")
    floors: int = Field(..., ge=1, le=10)
    quality_tier: Literal["basic", "standard", "premium"] = "standard"
    city_tier: Literal["tier1", "tier2", "tier3"] = "tier2"
    structure_type: Literal["RCC_frame", "load_bearing"] = "RCC_frame"
    foundation_type: Literal["normal", "raft", "pile"] = "normal"


class RoadRequest(BaseModel):
    length_ft: float = Field(..., gt=0)
    width_ft: float = Field(..., gt=0)
    thickness_inch: float = Field(6, gt=0, le=24)
    concrete_grade: Literal["M15", "M20", "M25", "M30"] = "M20"
    reinforcement: Literal["yes", "no"] = "yes"
    terrain: Literal["normal", "hilly"] = "normal"


# ---------- Response schema ----------

class CostResponse(BaseModel):
    estimated_cost_inr: float
    low_estimate_inr: float
    high_estimate_inr: float


# ---------- Routes ----------

@app.get("/")
def health_check():
    return {"status": "ok"}


@app.post("/predict/house", response_model=CostResponse)
def predict_house(req: HouseRequest):
    try:
        df = pd.DataFrame([req.model_dump()])
        cost = float(house_model.predict(df)[0])
        return CostResponse(
            estimated_cost_inr=round(cost, 2),
            low_estimate_inr=round(cost * 0.91, 2),
            high_estimate_inr=round(cost * 1.09, 2),
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.post("/predict/road", response_model=CostResponse)
def predict_road(req: RoadRequest):
    try:
        df = pd.DataFrame([req.model_dump()])
        cost = float(road_model.predict(df)[0])
        return CostResponse(
            estimated_cost_inr=round(cost, 2),
            low_estimate_inr=round(cost * 0.93, 2),
            high_estimate_inr=round(cost * 1.07, 2),
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
