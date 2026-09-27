import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error, r2_score, mean_absolute_percentage_error
import xgboost as xgb
import joblib

df = pd.read_csv("site_construction_data.csv")

FEATURES = [
    "site_type",
    "city_tier",
    "quality_tier",
    "road_quality",
    "scope_area_sqft",
    "floors",
    "planned_workers"
]
CAT_COLS = [
    "site_type",
    "city_tier",
    "quality_tier",
    "road_quality"
]

TARGETS = {
    "total_cost_inr": "total_cost_model.joblib",
    "duration_days": "duration_model.joblib",
    "machine_count": "machine_count_model.joblib",
}

preprocess = ColumnTransformer([
    ("cat", OneHotEncoder(handle_unknown="ignore"), CAT_COLS)
], remainder="passthrough")

results = []

for target, filename in TARGETS.items():
    X = df[FEATURES]
    y = df[target]
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    # Compare XGBoost vs Random Forest quickly, keep the better one
    candidates = {
        "XGBoost": Pipeline([
            ("prep", preprocess),
            ("model", xgb.XGBRegressor(n_estimators=300, max_depth=5, learning_rate=0.05,
                                        random_state=42, verbosity=0))
        ]),
        "Random Forest": Pipeline([
            ("prep", preprocess),
            ("model", RandomForestRegressor(n_estimators=250, max_depth=12,
                                             random_state=42, n_jobs=-1))
        ]),
    }

    best_name, best_pipeline, best_r2 = None, None, -1e9
    for name, pipeline in candidates.items():
        pipeline.fit(X_train, y_train)
        pred = pipeline.predict(X_test)
        r2 = r2_score(y_test, pred)
        mae = mean_absolute_error(y_test, pred)
        mape = mean_absolute_percentage_error(y_test, pred) * 100
        print(f"[{target}] {name}: R2={r2:.4f}  MAE={mae:,.1f}  MAPE={mape:.2f}%")
        if r2 > best_r2:
            best_name, best_pipeline, best_r2 = name, pipeline, r2

    pred = best_pipeline.predict(X_test)
    results.append({
        "target": target,
        "best_model": best_name,
        "R2": r2_score(y_test, pred),
        "MAE": mean_absolute_error(y_test, pred),
        "MAPE%": mean_absolute_percentage_error(y_test, pred) * 100,
    })

    joblib.dump(best_pipeline, filename)
    print(f"  -> saved {filename} (winner: {best_name})\n")

print("\n=== SUMMARY ===")
print(pd.DataFrame(results).to_string(index=False))
