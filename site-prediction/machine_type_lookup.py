"""
Machine TYPE recommendation is handled as a lookup table, not an ML model.

Why: the ML model predicts HOW MANY machines a site needs (a continuous
quantity that scales with size). WHICH TYPES of machines are needed is
mostly determined by site_type alone (a road always needs a roller; a
hospital never does) — this is a stable business rule, not something that
benefits from being learned statistically, and a lookup table is more
transparent and easier for you to edit than a black-box classifier.
"""

MACHINE_TYPE_RECOMMENDATIONS = {
    "Home": ["Concrete Mixer", "Vibrator", "Bar Bender"],
    "Apartment": ["Concrete Mixer", "Tower Crane", "Vibrator", "Bar Bender", "Hoist"],
    "Office": ["Concrete Mixer", "Tower Crane", "Vibrator", "Bar Bender", "Hoist"],
    "School": ["Concrete Mixer", "Vibrator", "Bar Bender", "Backhoe Loader"],
    "Hospital": ["Concrete Mixer", "Tower Crane", "Vibrator", "Bar Bender", "Hoist", "Generator"],
    "Road": ["Road Roller", "Concrete Mixer", "Paver", "Excavator", "Water Tanker"],
    "Bridge": ["Crane", "Excavator", "Concrete Pump", "Pile Driver", "Generator"],
    "Other": ["Concrete Mixer", "Excavator", "Vibrator"],
}


def recommended_machine_types(site_type: str) -> list[str]:
    return MACHINE_TYPE_RECOMMENDATIONS.get(site_type, MACHINE_TYPE_RECOMMENDATIONS["Other"])
