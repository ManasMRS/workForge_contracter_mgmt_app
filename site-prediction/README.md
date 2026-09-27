# Site Cost / Duration / Machine Prediction — Full Pipeline

## What's here

| File | Purpose |
|---|---|
| `schema_additions.js` | Fields to add to your `Site` and `Machine` Mongoose models |
| `generate_site_dataset.py` | Builds a synthetic training dataset (`site_construction_data.csv`) |
| `train_site_models.py` | Trains + compares models, saves the 3 winners as `.joblib` |
| `machine_type_lookup.py` | Rule-based table: site type → machine types needed |
| `predict_site.py` | Combined inference — load models, get a full prediction |
| `export_site_training_data.js` | Pulls your **real** historical labour cost + duration from MongoDB |
| `total_cost_model.joblib`, `duration_model.joblib`, `machine_count_model.joblib` | Trained models |

## Model performance (on synthetic data)

| Target | Best model | R² | MAPE |
|---|---|---|---|
| Total cost | XGBoost | 0.983 | 12.1% |
| Duration | Random Forest | 0.782 | 13.1% |
| Machine count | Random Forest | 0.966 | 18.0% |

Duration is the hardest to predict — real project timelines depend on things no model captures well (weather delays, permit holdups, supply chain issues). Treat the duration output as a planning baseline, not a guarantee.

## Path to real data (do this over time, not all at once)

1. **Now:** Add the fields in `schema_additions.js` to your `Site` and `Machine` models. Start filling in `scopeMetrics`, `qualityTier`, `cityTier`, and `plannedWorkers` for every **new** site you create.
2. **As sites complete:** Start setting `actualEndDate` when a site's status moves to `'Completed'`. This alone unlocks real duration data.
3. **When you're ready:** Start logging `materialCost` per site (manually, or build a small Expense-tracking collection if you want line-item detail later). Until this exists, material cost will always be an estimate, never a real number.
4. **Periodically:** Run `node export_site_training_data.js` — it pulls real labour cost + duration for every completed site straight from your existing `Attendance` + `Employee` collections (no schema change needed for labour cost specifically, since `Attendance.siteId` + `Employee.dailySalary` already give you what's needed).
5. **Once you have 50-100+ completed sites with real data:** Merge `real_site_training_data.csv` with (or replace) `site_construction_data.csv`, and rerun `train_site_models.py`. Real data will always outperform synthetic once you have enough of it.

## Using predictions

```python
from predict_site import predict_site

result = predict_site(
    site_type="Apartment",
    scope_area_sqft=1800,   # or length_ft * width_ft for Road/Bridge
    floors=4,
    planned_workers=25,
    city_tier="tier1",
    quality_tier="standard",
)
# {'estimated_total_cost_inr': ..., 'estimated_duration_days': ...,
#  'estimated_machine_count': ..., 'recommended_machine_types': [...]}
```

To serve this from your Flutter app, the same FastAPI pattern from the house/road estimator applies — wrap `predict_site()` in a `/predict/site` endpoint and add a corresponding screen. Happy to build that next if useful.

## Important caveats

- **These are still synthetic-data models.** The rate tables (₹/sqft by site type, productivity rates, machine intensity) are my calibrated estimates, not your actual historical costs. Accuracy will improve substantially once real data replaces them.
- **Bridge and Hospital data is sparser** in the synthetic set (5% and 9% of rows respectively) — if your business does a lot of one particular site type, consider generating more synthetic rows weighted toward that type, or prioritize getting real data for it first.
- **Machine type recommendations are a static lookup, not ML** — edit `machine_type_lookup.py` directly if your actual equipment needs differ from the defaults.
