"""
Interactive test harness for the site prediction models.
Run this after generate_site_dataset.py and train_site_models.py have
already been run (needs the 3 .joblib files present in this folder).

Usage:
    python3 test_predictions.py            # runs built-in test cases
    python3 test_predictions.py --interactive   # prompts you for inputs
"""
import sys
from predict_site import predict_site


def print_result(label, result):
    print(f"\n{'='*60}")
    print(label)
    print('='*60)
    print(f"  Total cost:        Rs {result['estimated_total_cost_inr']:,.0f}")
    print(f"  Duration:          {result['estimated_duration_days']} days "
          f"(~{result['estimated_duration_days']/30:.1f} months)")
    print(f"  Machines needed:   {result['estimated_machine_count']}")
    print(f"  Machine types:     {', '.join(result['recommended_machine_types'])}")


def run_test_suite():
    """A spread of test cases across site types, sizes, and quality tiers —
    sanity-check that the numbers scale the way you'd expect (bigger site =
    more cost/time/machines, premium > standard > basic, etc.)."""

    cases = [
        ("Small home, basic quality", dict(
            site_type="Home", scope_area_sqft=1000, floors=1,
            planned_workers=8, city_tier="tier2", quality_tier="basic")),

        ("Same home, premium quality", dict(
            site_type="Home", scope_area_sqft=1000, floors=1,
            planned_workers=8, city_tier="tier2", quality_tier="premium")),

        ("4-floor apartment, metro city", dict(
            site_type="Apartment", scope_area_sqft=2000, floors=4,
            planned_workers=30, city_tier="tier1", quality_tier="standard")),

        ("1km road, 2-lane", dict(
            site_type="Road", scope_area_sqft=1000 * 20,  # length * width
            planned_workers=20, city_tier="tier2", quality_tier="standard")),

        ("Small bridge span", dict(
            site_type="Bridge", scope_area_sqft=300 * 15,
            planned_workers=25, city_tier="tier1", quality_tier="standard")),

        ("Hospital, tier3 city", dict(
            site_type="Hospital", scope_area_sqft=5000, floors=3,
            planned_workers=50, city_tier="tier3", quality_tier="premium")),
    ]

    for label, params in cases:
        result = predict_site(**params)
        print_result(label, result)


def run_interactive():
    print("Enter site details (press Enter for defaults shown in brackets)\n")

    site_type = input("Site type [Home/Office/Road/Bridge/School/Hospital/Apartment/Other] (Home): ") or "Home"
    scope_area_sqft = float(input("Scope area sqft, or length*width for Road/Bridge (1500): ") or 1500)
    floors = int(input("Floors (1): ") or 1)
    planned_workers = int(input("Planned workers (10): ") or 10)
    city_tier = input("City tier [tier1/tier2/tier3] (tier2): ") or "tier2"
    quality_tier = input("Quality tier [basic/standard/premium] (standard): ") or "standard"

    result = predict_site(
        site_type=site_type,
        scope_area_sqft=scope_area_sqft,
        floors=floors,
        planned_workers=planned_workers,
        city_tier=city_tier,
        quality_tier=quality_tier,
    )
    print_result("Your site", result)


if __name__ == "__main__":
    if "--interactive" in sys.argv:
        run_interactive()
    else:
        run_test_suite()
