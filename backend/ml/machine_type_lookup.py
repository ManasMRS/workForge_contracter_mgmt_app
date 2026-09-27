"""
Machine Type Lookup
-------------------

Provides recommended construction machine types
based on the selected construction site type.

This module does NOT perform ML prediction.
The ML model predicts the number of machines,
while this module determines the suitable machine types.
"""


# ============================================================
# MACHINE RECOMMENDATIONS
# ============================================================

MACHINE_TYPES = {

    "Home": [
        "Concrete Mixer",
        "Cement Mixer",
        "Excavator",
        "Scaffolding",
    ],

    "Office": [
        "Tower Crane",
        "Concrete Mixer",
        "Excavator",
        "Scaffolding",
    ],

    "Road": [
        "Road Roller",
        "Paver Machine",
        "Excavator",
        "Motor Grader",
        "Water Tanker",
    ],

    "Bridge": [
        "Tower Crane",
        "Concrete Mixer",
        "Excavator",
        "Crane",
        "Concrete Pump",
    ],

    "School": [
        "Concrete Mixer",
        "Excavator",
        "Scaffolding",
        "Crane",
    ],

    "Hospital": [
        "Tower Crane",
        "Concrete Mixer",
        "Excavator",
        "Scaffolding",
        "Concrete Pump",
    ],

    "Apartment": [
        "Tower Crane",
        "Concrete Mixer",
        "Excavator",
        "Concrete Pump",
        "Scaffolding",
    ],

    "Other": [
        "Excavator",
        "Concrete Mixer",
        "Crane",
        "Scaffolding",
    ],
}


# ============================================================
# GET RECOMMENDED MACHINE TYPES
# ============================================================

def recommended_machine_types(site_type):
    """
    Return recommended machine types for a site.

    Parameters
    ----------
    site_type : str
        Construction site type.

    Returns
    -------
    list[str]
        Recommended machine types.
    """

    if not site_type:
        return MACHINE_TYPES["Other"]

    # Normalize input
    normalized_site_type = str(site_type).strip()

    return MACHINE_TYPES.get(
        normalized_site_type,
        MACHINE_TYPES["Other"]
    )


# ============================================================
# MAIN TEST
# ============================================================

if __name__ == "__main__":

    print("\nWorkForge Machine Recommendations")
    print("=" * 45)

    for site_type in MACHINE_TYPES:

        machines = recommended_machine_types(site_type)

        print(f"\n{site_type}:")
        for machine in machines:
            print(f"  - {machine}")