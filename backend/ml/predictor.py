"""
WorkForge Construction Site ML Predictor
=========================================

Loads trained machine-learning models and predicts:

1. Total construction cost
2. Construction duration
3. Required machine count
4. Recommended machine types

Expected trained model files:

    total_cost_model.joblib
    duration_model.joblib
    machine_count_model.joblib
"""


# ============================================================
# IMPORTS
# ============================================================

from pathlib import Path

import joblib
import pandas as pd
try:
    from .machine_type_lookup import recommended_machine_types
except ImportError:
    from machine_type_lookup import recommended_machine_types

# ============================================================
# MODEL DIRECTORY
# ============================================================

BASE_DIR = Path(__file__).resolve().parent


# ============================================================
# MODEL PATHS
# ============================================================

TOTAL_COST_MODEL_PATH = (
    BASE_DIR / "total_cost_model.joblib"
)

DURATION_MODEL_PATH = (
    BASE_DIR / "duration_model.joblib"
)

MACHINE_COUNT_MODEL_PATH = (
    BASE_DIR / "machine_count_model.joblib"
)


# ============================================================
# LOAD MODELS
# ============================================================

def load_model(path):
    """
    Load a trained joblib model.

    Parameters
    ----------
    path : Path
        Path to the .joblib model.

    Returns
    -------
    object
        Loaded ML model.
    """

    if not path.exists():

        raise FileNotFoundError(
            f"ML model file not found: {path}"
        )

    return joblib.load(path)


# Load trained models
total_cost_model = load_model(
    TOTAL_COST_MODEL_PATH
)

duration_model = load_model(
    DURATION_MODEL_PATH
)

machine_count_model = load_model(
    MACHINE_COUNT_MODEL_PATH
)


# ============================================================
# PREDICTION FUNCTION
# ============================================================

def predict_site(
    site_type,
    scope_area_sqft,
    floors=1,
    planned_workers=10,
    city_tier="tier2",
    quality_tier="standard",
    road_quality="Not Applicable",
):
    """
    Predict construction cost, duration and machine requirement.

    Parameters
    ----------
    site_type : str
        Home, Office, Road, Bridge, School,
        Hospital, Apartment or Other.

    scope_area_sqft : float
        Construction area in square feet.

        For buildings:
            Built-up area per floor.

        For roads:
            Length x Width area.

        For bridges:
            Length x effective width.

    floors : int
        Number of floors.

    planned_workers : int
        Planned construction workforce.

    city_tier : str
        tier1, tier2 or tier3.

    quality_tier : str
        basic, standard or premium.

    road_quality : str
        pichu, concrete or Not Applicable.

    Returns
    -------
    dict
        Prediction results.
    """

    # ========================================================
    # INPUT VALIDATION
    # ========================================================

    if not site_type:
        raise ValueError(
            "site_type is required."
        )

    if scope_area_sqft is None:
        raise ValueError(
            "scope_area_sqft is required."
        )

    try:
        scope_area_sqft = float(
            scope_area_sqft
        )
    except (TypeError, ValueError):

        raise ValueError(
            "scope_area_sqft must be a number."
        )

    if scope_area_sqft <= 0:

        raise ValueError(
            "scope_area_sqft must be greater than 0."
        )


    try:
        floors = int(floors)
    except (TypeError, ValueError):

        raise ValueError(
            "floors must be an integer."
        )

    if floors < 1:

        raise ValueError(
            "floors must be at least 1."
        )


    try:
        planned_workers = int(
            planned_workers
        )
    except (TypeError, ValueError):

        raise ValueError(
            "planned_workers must be an integer."
        )

    if planned_workers < 1:

        raise ValueError(
            "planned_workers must be at least 1."
        )


    # ========================================================
    # NORMALIZE INPUTS
    # ========================================================

    site_type = str(
        site_type
    ).strip()

    city_tier = str(
        city_tier
    ).strip().lower()

    quality_tier = str(
        quality_tier
    ).strip().lower()

    road_quality = str(
        road_quality
    ).strip()


    # ========================================================
    # VALID VALUES
    # ========================================================

    valid_site_types = [
        "Home",
        "Office",
        "Road",
        "Bridge",
        "School",
        "Hospital",
        "Apartment",
        "Other",
    ]

    valid_city_tiers = [
        "tier1",
        "tier2",
        "tier3",
    ]

    valid_quality_tiers = [
        "basic",
        "standard",
        "premium",
    ]


    if site_type not in valid_site_types:

        raise ValueError(
            f"Invalid site_type: {site_type}"
        )


    if city_tier not in valid_city_tiers:

        raise ValueError(
            f"Invalid city_tier: {city_tier}"
        )


    if quality_tier not in valid_quality_tiers:

        raise ValueError(
            f"Invalid quality_tier: {quality_tier}"
        )


    # ========================================================
    # ROAD QUALITY
    # ========================================================

    if site_type == "Road":

        if road_quality not in [
            "pichu",
            "concrete",
        ]:

            road_quality = "pichu"

    else:

        road_quality = "Not Applicable"


    # ========================================================
    # CREATE MODEL INPUT DATAFRAME
    # ========================================================

    input_data = pd.DataFrame([
        {
            "site_type": site_type,

            "city_tier": city_tier,

            "quality_tier": quality_tier,

            "road_quality": road_quality,

            "scope_area_sqft": scope_area_sqft,

            "floors": floors,

            "planned_workers": planned_workers,
        }
    ])


    # ========================================================
    # ML PREDICTIONS
    # ========================================================

    try:

        total_cost = (
            total_cost_model
            .predict(input_data)[0]
        )

        duration = (
            duration_model
            .predict(input_data)[0]
        )

        machine_count = (
            machine_count_model
            .predict(input_data)[0]
        )

    except Exception as e:

        raise RuntimeError(
            f"ML prediction failed: {e}"
        )


    # ========================================================
    # CLEAN PREDICTIONS
    # ========================================================

    total_cost = max(
        0,
        float(total_cost)
    )

    duration = max(
        1,
        float(duration)
    )

    machine_count = max(
        1,
        float(machine_count)
    )


    # ========================================================
    # MACHINE TYPE RECOMMENDATION
    # ========================================================

    machines = recommended_machine_types(
        site_type
    )


    # ========================================================
    # FINAL RESULT
    # ========================================================

    result = {

        "estimated_total_cost_inr":
            round(total_cost, 0),

        "estimated_duration_days":
            round(duration),

        "estimated_machine_count":
            round(machine_count),

        "recommended_machine_types":
            machines,
    }


    return result


# ============================================================
# COMMAND LINE TEST
# ============================================================

if __name__ == "__main__":
    import json
    import sys

    # ------------------------------------------------------------
    # NODE.JS API MODE
    # ------------------------------------------------------------
    if len(sys.argv) > 1 and sys.argv[1] == "--stdin":
        try:
            payload = json.load(sys.stdin)

            result = predict_site(
                site_type=payload.get("site_type"),
                scope_area_sqft=payload.get("scope_area_sqft"),
                floors=payload.get("floors", 1),
                planned_workers=payload.get("planned_workers", 10),
                city_tier=payload.get("city_tier", "tier2"),
                quality_tier=payload.get("quality_tier", "standard"),
                road_quality=payload.get(
                    "road_quality",
                    "Not Applicable"
                ),
            )

            print(json.dumps(result))
            sys.exit(0)

        except Exception as e:
            print(
                json.dumps({
                    "error": str(e)
                })
            )
            sys.exit(1)

    # ------------------------------------------------------------
    # DIRECT TERMINAL TEST MODE
    # ------------------------------------------------------------

    print("=" * 60)
    print("WorkForge ML Prediction Test")
    print("=" * 60)

    apartment_result = predict_site(
        site_type="Apartment",
        scope_area_sqft=1800,
        floors=4,
        planned_workers=25,
        city_tier="tier1",
        quality_tier="standard",
        road_quality="Not Applicable",
    )

    print("\nApartment Prediction")
    print("-" * 60)
    print(apartment_result)

    road_result = predict_site(
        site_type="Road",
        scope_area_sqft=500 * 20,
        floors=1,
        planned_workers=15,
        city_tier="tier2",
        quality_tier="standard",
        road_quality="pichu",
    )

    print("\nRoad Prediction")
    print("-" * 60)
    print(road_result)

    print()
    print("=" * 60)
    print("WorkForge ML Prediction Test")
    print("=" * 60)


    # --------------------------------------------------------
    # Apartment
    # --------------------------------------------------------

    print("\nApartment Prediction")
    print("-" * 60)

    apartment_result = predict_site(

        site_type="Apartment",

        scope_area_sqft=1800,

        floors=4,

        planned_workers=25,

        city_tier="tier1",

        quality_tier="standard",

        road_quality="Not Applicable",
    )

    print(apartment_result)


    # --------------------------------------------------------
    # Road
    # --------------------------------------------------------

    print("\nRoad Prediction")
    print("-" * 60)

    road_result = predict_site(

        site_type="Road",

        scope_area_sqft=500 * 20,

        floors=1,

        planned_workers=15,

        city_tier="tier2",

        quality_tier="standard",

        road_quality="pichu",
    )

    print(road_result)