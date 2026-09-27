import numpy as np
import pandas as pd

rng = np.random.default_rng(42)

N = 8000

site_type = rng.choice(
    ["Home", "Office", "Road", "Bridge", "School", "Hospital", "Apartment", "Other"],
    N, p=[0.20, 0.14, 0.16, 0.05, 0.11, 0.09, 0.20, 0.05]
)

city_tier = rng.choice(["tier1", "tier2", "tier3"], N, p=[0.30, 0.45, 0.25])
quality_tier = rng.choice(
    ["basic", "standard", "premium"],
    N,
    p=[0.35, 0.45, 0.20]
)

# Road-specific quality
road_quality = np.where(
    site_type == "Road",
    rng.choice(
        ["Pichu Road", "Concrete Road"],
        N,
        p=[0.45, 0.55]
    ),
    "Not Applicable"
)
# ------------------------------------------------------------------
# Scope: unify all site types onto one "scope_area_sqft" measure.
# Vertical structures use area_sqft * floors. Road/Bridge use length*width
# (already an area, floors fixed at 1).
# ------------------------------------------------------------------
VERTICAL_TYPES = {"Home", "Apartment", "Office", "School", "Hospital", "Other"}

area_sqft = rng.integers(400, 6000, N).astype(float)
floors = np.where(
    np.isin(site_type, list(VERTICAL_TYPES)),
    rng.integers(1, 5, N),
    1
)

length_ft = rng.integers(50, 5000, N).astype(float)
width_ft = rng.integers(8, 40, N).astype(float)

scope_area_sqft = np.where(
    np.isin(site_type, ["Road", "Bridge"]),
    length_ft * width_ft,
    area_sqft
)
# For bridges, scale down — bridges are usually narrower spans, not huge sqft slabs
scope_area_sqft = np.where(site_type == "Bridge", length_ft * (width_ft * 0.4), scope_area_sqft)

total_build_area = scope_area_sqft * floors

# ------------------------------------------------------------------
# Planned workforce — loosely scales with project size, with real variance
# ------------------------------------------------------------------
planned_workers = np.clip(
    (total_build_area / 300) * rng.normal(1.0, 0.35, N),
    3, 300
).round().astype(int)

# ------------------------------------------------------------------
# COST MODEL
# ------------------------------------------------------------------
BASE_RATE = {  # INR per sqft, standard quality, tier2 city
    "Home": 1800, "Apartment": 1900, "Office": 2100, "School": 2000,
    "Hospital": 2800, "Road": 480, "Bridge": 9000, "Other": 1700
}
base_rate = pd.Series(site_type).map(BASE_RATE).values

quality_mult = pd.Series(quality_tier).map({"basic": 0.75, "standard": 1.0, "premium": 1.45}).values
city_mult = pd.Series(city_tier).map({"tier1": 1.25, "tier2": 1.0, "tier3": 0.85}).values
floor_mult = 1 + 0.035 * (floors - 1)

rate_per_sqft = base_rate * quality_mult * city_mult * floor_mult

noise_cost = rng.normal(1.0, 0.10, N)
total_cost_inr = total_build_area * rate_per_sqft * noise_cost

# Split into labour / material. Roads/bridges lean material+machinery heavy;
# buildings lean more evenly split.
MATERIAL_SHARE = {
    "Home": 0.60, "Apartment": 0.62, "Office": 0.60, "School": 0.58,
    "Hospital": 0.55, "Road": 0.72, "Bridge": 0.65, "Other": 0.60
}
material_share = pd.Series(site_type).map(MATERIAL_SHARE).values
material_share = np.clip(material_share + rng.normal(0, 0.04, N), 0.3, 0.85)

material_cost_inr = total_cost_inr * material_share
labour_cost_inr = total_cost_inr - material_cost_inr

# ------------------------------------------------------------------
# DURATION MODEL
# ------------------------------------------------------------------
PRODUCTIVITY = {  # sqft built per worker per day
    "Home": 8, "Apartment": 7, "Office": 7.5, "School": 8,
    "Hospital": 5, "Road": 15, "Bridge": 3, "Other": 8
}
productivity = pd.Series(site_type).map(PRODUCTIVITY).values

BASE_MOBILIZATION_DAYS = {  # minimum days regardless of size (setup, permits, curing)
    "Home": 20, "Apartment": 30, "Office": 30, "School": 35,
    "Hospital": 60, "Road": 15, "Bridge": 90, "Other": 20
}
base_days = pd.Series(site_type).map(BASE_MOBILIZATION_DAYS).values

quality_duration_mult = pd.Series(quality_tier).map({"basic": 0.85, "standard": 1.0, "premium": 1.25}).values

core_duration = (total_build_area / (planned_workers * productivity)) * quality_duration_mult
duration_days = base_days + core_duration
duration_days = duration_days * rng.normal(1.0, 0.10, N)
duration_days = np.clip(duration_days, 5, None).round().astype(int)

# ------------------------------------------------------------------
# MACHINE REQUIREMENT MODEL
# ------------------------------------------------------------------
MACHINE_INTENSITY = {  # machines per 10,000 sqft of build area
    "Home": 1.0, "Apartment": 2.0, "Office": 2.0, "School": 2.0,
    "Hospital": 3.0, "Road": 4.0, "Bridge": 6.0, "Other": 1.5
}
machine_intensity = pd.Series(site_type).map(MACHINE_INTENSITY).values

machine_count = 1 + machine_intensity * (total_build_area / 10000)
machine_count = machine_count * rng.normal(1.0, 0.15, N)
machine_count = np.clip(machine_count, 1, None).round().astype(int)

# ------------------------------------------------------------------
# Assemble
# ------------------------------------------------------------------
df = pd.DataFrame({
    "site_type": site_type,
    "city_tier": city_tier,
    "quality_tier": quality_tier,
    "scope_area_sqft": scope_area_sqft.round(1),
    "floors": floors,
    "planned_workers": planned_workers,
    "total_build_area_sqft": total_build_area.round(1),
    "labour_cost_inr": labour_cost_inr.round(0),
    "material_cost_inr": material_cost_inr.round(0),
    "total_cost_inr": total_cost_inr.round(0),
    "duration_days": duration_days,
    "machine_count": machine_count,
})

df.to_csv("site_construction_data.csv", index=False)
print("Dataset shape:", df.shape)
print(df.head(10))
print("\nBy site type — mean cost, duration, machines:")
print(df.groupby("site_type")[["total_cost_inr", "duration_days", "machine_count"]].mean().round(0))
