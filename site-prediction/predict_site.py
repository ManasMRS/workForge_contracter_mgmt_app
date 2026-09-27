"""
Load the trained models and predict cost, duration, and machine
requirement for a planned construction site.
"""
import pandas as pd
import joblib
from machine_type_lookup import recommended_machine_types

total_cost_model = joblib.load("total_cost_model.joblib")
duration_model = joblib.load("duration_model.joblib")
machine_count_model = joblib.load("machine_count_model.joblib")


def predict_site(
    site_type,
    scope_area_sqft,
    floors=1,
    planned_workers=10,
    city_tier="tier2",
    quality_tier="standard",
    road_quality="Not Applicable"
):
    """
    site_type: 'Home' | 'Office' | 'Road' | 'Bridge' | 'School' | 'Hospital' | 'Apartment' | 'Other'
    scope_area_sqft: built-up area (vertical types) or length*width (Road/Bridge)
    floors: only meaningful for vertical types; leave 1 for Road/Bridge
    planned_workers: intended crew size
    city_tier: 'tier1' | 'tier2' | 'tier3'
    quality_tier: 'basic' | 'standard' | 'premium'
    """
    df = pd.DataFrame([{
    "site_type": site_type,
    "city_tier": city_tier,
    "quality_tier": quality_tier,
    "road_quality": road_quality,
    "scope_area_sqft": scope_area_sqft,
    "floors": floors,
    "planned_workers": planned_workers,
    }])

    total_cost = float(total_cost_model.predict(df)[0])
    duration = float(duration_model.predict(df)[0])
    machine_count = float(machine_count_model.predict(df)[0])

    return {
        "estimated_total_cost_inr": round(total_cost, 0),
        "estimated_duration_days": round(duration),
        "estimated_machine_count": round(machine_count),
        "recommended_machine_types": recommended_machine_types(site_type),
    }


if __name__ == "__main__":
    result = predict_site(
        site_type="Apartment",
        scope_area_sqft=1800,
        floors=4,
        planned_workers=25,
        city_tier="tier1",
        quality_tier="standard",
    )
    print(result)

    result = predict_site(
        site_type="Road",
        scope_area_sqft=500 * 20,  # length * width
        planned_workers=15,
        city_tier="tier2",
        quality_tier="standard",
    )
    print(result)







