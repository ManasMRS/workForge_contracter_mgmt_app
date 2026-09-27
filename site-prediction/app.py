from flask import Flask, request, render_template_string, jsonify
from predict_site import predict_site

app = Flask(__name__)

METERS_TO_FEET = 3.28084


# =========================================================
# SITE CONFIGURATION
# =========================================================

SITE_TYPES = [
    "Home",
    "Office",
    "Road",
    "Bridge",
    "School",
    "Hospital",
    "Apartment",
    "Other",
]

LINEAR_TYPES = {
    "Road",
    "Bridge",
}

CITY_TIERS = [
    "tier1",
    "tier2",
    "tier3",
]

QUALITY_TIERS = [
    "basic",
    "standard",
    "premium",
]

ROAD_QUALITY = [
    "pichu",
    "concrete",
]


# =========================================================
# DEFAULT FORM VALUES
# =========================================================

DEFAULT_FORM = {
    "site_type": "Home",
    "area_sqft": 1500,
    "floors": 1,
    "length_m": 150,
    "width_m": 6,
    "planned_workers": 10,
    "city_tier": "tier2",
    "quality_tier": "standard",
    "road_quality": "pichu",
}


# =========================================================
# HELPER
# =========================================================

def clean_result(result):
    """
    Convert prediction result into JSON-safe Python values.

    This also handles numpy numeric values returned by
    scikit-learn/joblib models.
    """

    if result is None:
        return None

    if isinstance(result, dict):

        return {
            key: clean_result(value)
            for key, value in result.items()
        }

    if isinstance(result, list):

        return [
            clean_result(value)
            for value in result
        ]

    if isinstance(result, tuple):

        return [
            clean_result(value)
            for value in result
        ]

    # Handle numpy scalar values without requiring numpy import.
    if hasattr(result, "item"):

        try:
            return result.item()
        except Exception:
            pass

    return result


# =========================================================
# BASIC CORS
# =========================================================
#
# This allows your Flutter application to communicate with
# this Flask server during development.
#
# For production, restrict Access-Control-Allow-Origin to
# your actual application/domain.
# =========================================================

@app.after_request
def add_cors_headers(response):

    response.headers["Access-Control-Allow-Origin"] = "*"

    response.headers["Access-Control-Allow-Headers"] = (
        "Content-Type, Authorization"
    )

    response.headers["Access-Control-Allow-Methods"] = (
        "GET, POST, OPTIONS"
    )

    return response


# =========================================================
# HTML PAGE
# =========================================================

PAGE = """
<!DOCTYPE html>
<html>

<head>

  <title>Site Cost Estimator</title>

  <meta
    name="viewport"
    content="width=device-width, initial-scale=1"
  >

  <style>

    body {
      font-family:
        -apple-system,
        BlinkMacSystemFont,
        "Segoe UI",
        sans-serif;

      max-width: 560px;

      margin: 40px auto;

      padding: 0 20px;

      background: #f6f4ee;

      color: #1f2422;
    }


    h1 {
      font-size: 1.4rem;
      margin-bottom: 24px;
    }


    label {
      display: block;

      margin-top: 14px;

      font-size: 0.85rem;

      font-weight: 600;

      color: #1b3a5c;
    }


    select,
    input {

      width: 100%;

      padding: 10px;

      margin-top: 4px;

      border:
        1.5px solid #2e5c8a;

      border-radius: 4px;

      font-size: 1rem;

      box-sizing: border-box;

      background: white;
    }


    button {

      margin-top: 20px;

      width: 100%;

      padding: 12px;

      background: #1b3a5c;

      color: white;

      border: none;

      border-radius: 4px;

      font-size: 1rem;

      cursor: pointer;
    }


    button:hover {

      background: #2e5c8a;

    }


    .result {

      margin-top: 24px;

      padding: 18px;

      border:
        2px dashed #2e5c8a;

      background:
        rgba(27, 58, 92, 0.05);

      border-radius: 4px;
    }


    .result h2 {

      margin-top: 0;

      font-size: 1.6rem;

      color: #1b3a5c;
    }


    .result p {

      margin: 6px 0;

    }


    .error {

      margin-top: 20px;

      padding: 12px;

      background: #fde2e2;

      color: #a12626;

      border-radius: 4px;
    }


    .hint {

      font-size: 0.78rem;

      color: #5b5346;

      margin-top: 6px;

      line-height: 1.4;
    }


    .row {

      display: flex;

      gap: 12px;
    }


    .row > div {

      flex: 1;

    }


    .hidden {

      display: none;

    }


    .worker-info {

      margin-top: 8px;

      padding: 10px;

      background: #eef4fa;

      border-left:
        4px solid #2e5c8a;

      font-size: 0.8rem;

      line-height: 1.4;
    }


    .road-info {

      margin-top: 10px;

      padding: 10px;

      background: #f1eee5;

      border-radius: 4px;

      font-size: 0.8rem;

      line-height: 1.4;
    }

  </style>

</head>


<body>

  <h1>
    Site Cost / Duration / Machine Estimator
  </h1>


  <form
    method="POST"
    id="siteForm"
  >


    <!-- ================================================= -->
    <!-- SITE TYPE -->
    <!-- ================================================= -->

    <label>
      Site type
    </label>

    <select
      name="site_type"
      id="siteType"
      onchange="updateForm()"
    >

      {% for t in site_types %}

        <option
          value="{{ t }}"
          {% if t == form.site_type %}
          selected
          {% endif %}
        >

          {{ t }}

        </option>

      {% endfor %}

    </select>


    <!-- ================================================= -->
    <!-- VERTICAL STRUCTURES -->
    <!-- ================================================= -->

    <div id="verticalFields">

      <label>
        Built-up area per floor (sq ft)
      </label>

      <input
        type="number"
        name="area_sqft"
        id="areaSqft"
        value="{{ form.area_sqft }}"
        min="1"
        step="any"
      >


      <label>
        Floors
      </label>

      <input
        type="number"
        name="floors"
        id="floors"
        value="{{ form.floors }}"
        min="1"
      >

    </div>


    <!-- ================================================= -->
    <!-- ROAD / BRIDGE -->
    <!-- ================================================= -->

    <div
      id="linearFields"
      class="hidden"
    >

      <div class="row">

        <div>

          <label>
            Length (meters)
          </label>

          <input
            type="number"
            name="length_m"
            id="lengthM"
            value="{{ form.length_m }}"
            min="1"
            step="any"
          >

        </div>


        <div>

          <label>
            Width (meters)
          </label>

          <input
            type="number"
            name="width_m"
            id="widthM"
            value="{{ form.width_m }}"
            min="1"
            step="any"
          >

        </div>

      </div>


      <div class="hint">

        Floors don't apply to roads or bridges.

      </div>


      <div
        id="roadInfo"
        class="road-info hidden"
      >

        Road area and workforce are
        calculated automatically.

      </div>

    </div>


    <!-- ================================================= -->
    <!-- PLANNED WORKERS -->
    <!-- ================================================= -->

    <label>
      Planned workers
    </label>

    <input
      type="number"
      name="planned_workers"
      id="plannedWorkers"
      value="{{ form.planned_workers }}"
      min="1"
      required
    >

    <div
      id="workerInfo"
      class="worker-info hidden"
    ></div>


    <!-- ================================================= -->
    <!-- CITY TIER -->
    <!-- ================================================= -->

    <label>
      City tier
    </label>

    <select name="city_tier">

      {% for c in city_tiers %}

        <option
          value="{{ c }}"
          {% if c == form.city_tier %}
          selected
          {% endif %}
        >

          {{ c }}

        </option>

      {% endfor %}

    </select>


    <!-- ================================================= -->
    <!-- NORMAL QUALITY -->
    <!-- ================================================= -->

    <div id="normalQuality">

      <label>
        Construction Quality
      </label>

      <select
        name="quality_tier"
        id="qualityTier"
        onchange="updateQualityHint()"
      >

        <option
          value="basic"
          {% if form.quality_tier == "basic" %}
          selected
          {% endif %}
        >
          Basic
        </option>

        <option
          value="standard"
          {% if form.quality_tier == "standard" %}
          selected
          {% endif %}
        >
          Standard
        </option>

        <option
          value="premium"
          {% if form.quality_tier == "premium" %}
          selected
          {% endif %}
        >
          Premium
        </option>

      </select>

    </div>


    <!-- ================================================= -->
    <!-- ROAD QUALITY -->
    <!-- ================================================= -->

    <div
      id="roadQuality"
      class="hidden"
    >

      <label>
        Road Type
      </label>

      <select
        name="road_quality"
        id="roadQualitySelect"
      >

        <option
          value="pichu"
          {% if form.road_quality == "pichu" %}
          selected
          {% endif %}
        >
          Pichu Road
        </option>

        <option
          value="concrete"
          {% if form.road_quality == "concrete" %}
          selected
          {% endif %}
        >
          Concrete Road
        </option>

      </select>


      <div class="hint">

        Pichu Road = bituminous/asphalt-type road.
        Concrete Road = cement concrete pavement.

      </div>

    </div>


    <div
      class="hint"
      id="qualityHint"
    ></div>


    <!-- ================================================= -->
    <!-- SUBMIT -->
    <!-- ================================================= -->

    <button type="submit">

      Get Estimate

    </button>

  </form>


  <!-- ================================================= -->
  <!-- ERROR -->
  <!-- ================================================= -->

  {% if error %}

    <div class="error">

      {{ error }}

    </div>

  {% endif %}


  <!-- ================================================= -->
  <!-- RESULT -->
  <!-- ================================================= -->

  {% if result %}

    <div class="result">

      <h2>

        ₹{{ "{:,.0f}".format(
          result.estimated_total_cost_inr
        ) }}

      </h2>


      <p>

        <strong>
          Duration:
        </strong>

        {{ result.estimated_duration_days }}

        days

        (~{{
          "%.1f"|format(
            result.estimated_duration_days / 30
          )
        }} months)

      </p>


      <p>

        <strong>
          Machines needed:
        </strong>

        {{ result.estimated_machine_count }}

      </p>


      <p>

        <strong>
          Machine types:
        </strong>

        {{
          result.recommended_machine_types
          |join(', ')
        }}

      </p>

    </div>

  {% endif %}


  <!-- ================================================= -->
  <!-- JAVASCRIPT -->
  <!-- ================================================= -->

  <script>

    const LINEAR_TYPES = [
      "Road",
      "Bridge"
    ];


    const QUALITY_DESCRIPTIONS = {

      basic:
        "Economical construction quality.",

      standard:
        "Mid-range construction quality.",

      premium:
        "High-end construction quality."

    };


    // ===================================================
    // UPDATE FORM
    // ===================================================

    function updateForm() {

      const siteType =
        document.getElementById(
          "siteType"
        ).value;


      const vertical =
        document.getElementById(
          "verticalFields"
        );


      const linear =
        document.getElementById(
          "linearFields"
        );


      const roadQuality =
        document.getElementById(
          "roadQuality"
        );


      const normalQuality =
        document.getElementById(
          "normalQuality"
        );


      const area =
        document.getElementById(
          "areaSqft"
        );


      const length =
        document.getElementById(
          "lengthM"
        );


      const width =
        document.getElementById(
          "widthM"
        );


      const roadInfo =
        document.getElementById(
          "roadInfo"
        );


      // -----------------------------------------------
      // ROAD / BRIDGE
      // -----------------------------------------------

      if (
        LINEAR_TYPES.includes(siteType)
      ) {

        vertical.classList.add(
          "hidden"
        );

        linear.classList.remove(
          "hidden"
        );

        area.removeAttribute(
          "required"
        );

        length.setAttribute(
          "required",
          "required"
        );

        width.setAttribute(
          "required",
          "required"
        );

      }


      // -----------------------------------------------
      // VERTICAL BUILDING
      // -----------------------------------------------

      else {

        vertical.classList.remove(
          "hidden"
        );

        linear.classList.add(
          "hidden"
        );

        area.setAttribute(
          "required",
          "required"
        );

        length.removeAttribute(
          "required"
        );

        width.removeAttribute(
          "required"
        );

      }


      // -----------------------------------------------
      // ROAD
      // -----------------------------------------------

      if (
        siteType === "Road"
      ) {

        roadQuality.classList.remove(
          "hidden"
        );

        normalQuality.classList.add(
          "hidden"
        );

        roadInfo.classList.remove(
          "hidden"
        );

        updateRoadWorkers();

      }


      // -----------------------------------------------
      // BRIDGE
      // -----------------------------------------------

      else if (
        siteType === "Bridge"
      ) {

        roadQuality.classList.add(
          "hidden"
        );

        normalQuality.classList.remove(
          "hidden"
        );

        roadInfo.classList.add(
          "hidden"
        );

      }


      // -----------------------------------------------
      // BUILDINGS
      // -----------------------------------------------

      else {

        roadQuality.classList.add(
          "hidden"
        );

        normalQuality.classList.remove(
          "hidden"
        );

        roadInfo.classList.add(
          "hidden"
        );

      }


      updateQualityHint();

    }


    // ===================================================
    // AUTOMATIC ROAD WORKERS
    // ===================================================

    function updateRoadWorkers() {

      const siteType =
        document.getElementById(
          "siteType"
        ).value;


      if (
        siteType !== "Road"
      ) {

        return;

      }


      const lengthM =
        parseFloat(
          document.getElementById(
            "lengthM"
          ).value
        ) || 0;


      const widthM =
        parseFloat(
          document.getElementById(
            "widthM"
          ).value
        ) || 0;


      if (
        lengthM <= 0 ||
        widthM <= 0
      ) {

        return;

      }


      // Convert m² to ft²

      const areaSqft =
        lengthM *
        widthM *
        Math.pow(
          3.28084,
          2
        );


      // Workforce rule

      let workers =
        Math.round(
          areaSqft / 300
        );


      // Minimum 10, maximum 300

      workers =
        Math.max(
          10,
          Math.min(
            300,
            workers
          )
        );


      document.getElementById(
        "plannedWorkers"
      ).value = workers;


      document.getElementById(
        "workerInfo"
      ).classList.remove(
        "hidden"
      );


      document.getElementById(
        "workerInfo"
      ).innerHTML =
        "Road area: <strong>" +
        Math.round(
          areaSqft
        ).toLocaleString() +
        " sq ft</strong><br>" +
        "Recommended workforce: <strong>" +
        workers +
        " workers</strong>";

    }


    // ===================================================
    // QUALITY DESCRIPTION
    // ===================================================

    function updateQualityHint() {

      const qualityElement =
        document.getElementById(
          "qualityTier"
        );


      const hint =
        document.getElementById(
          "qualityHint"
        );


      if (
        qualityElement &&
        hint
      ) {

        const quality =
          qualityElement.value;


        hint.textContent =
          QUALITY_DESCRIPTIONS[
            quality
          ] || "";

      }

    }


    // ===================================================
    // ROAD INPUT LISTENERS
    // ===================================================

    document
      .getElementById("lengthM")
      .addEventListener(
        "input",
        updateRoadWorkers
      );


    document
      .getElementById("widthM")
      .addEventListener(
        "input",
        updateRoadWorkers
      );


    // ===================================================
    // INITIAL SETUP
    // ===================================================

    updateForm();

  </script>

</body>

</html>
"""


# =========================================================
# WEB APPLICATION ROUTE
# =========================================================

@app.route("/", methods=["GET", "POST"])
def index():

    form = dict(DEFAULT_FORM)

    result = None

    error = None


    if request.method == "POST":

        try:

            # =================================================
            # BASIC FORM VALUES
            # =================================================

            form["site_type"] = request.form[
                "site_type"
            ]

            form["city_tier"] = request.form[
                "city_tier"
            ]


            # =================================================
            # ROAD QUALITY
            # =================================================

            form["road_quality"] = request.form.get(
                "road_quality",
                "pichu"
            )


            # =================================================
            # NORMAL QUALITY
            # =================================================

            form["quality_tier"] = request.form.get(
                "quality_tier",
                "standard"
            )


            # =================================================
            # CHECK LINEAR SITE
            # =================================================

            is_linear = (
                form["site_type"]
                in LINEAR_TYPES
            )


            # =================================================
            # ROAD / BRIDGE
            # =================================================

            if is_linear:

                length_m = float(
                    request.form[
                        "length_m"
                    ]
                )

                width_m = float(
                    request.form[
                        "width_m"
                    ]
                )


                if (
                    length_m <= 0
                    or width_m <= 0
                ):

                    raise ValueError(
                        "Length and width "
                        "must be greater than 0."
                    )


                form["length_m"] = length_m

                form["width_m"] = width_m


                # ---------------------------------------------
                # Convert meters → feet
                # ---------------------------------------------

                length_ft = (
                    length_m *
                    METERS_TO_FEET
                )

                width_ft = (
                    width_m *
                    METERS_TO_FEET
                )


                # =================================================
                # BRIDGE
                # =================================================

                if (
                    form["site_type"]
                    == "Bridge"
                ):

                    scope_area_sqft = (
                        length_ft *
                        (
                            width_ft *
                            0.4
                        )
                    )

                    floors = 1


                    form["planned_workers"] = int(
                        request.form.get(
                            "planned_workers",
                            10
                        )
                    )


                # =================================================
                # ROAD
                # =================================================

                else:

                    scope_area_sqft = (
                        length_ft *
                        width_ft
                    )

                    floors = 1


                    # ---------------------------------------------
                    # Automatically calculate workers
                    # ---------------------------------------------

                    calculated_workers = round(
                        scope_area_sqft /
                        300
                    )


                    calculated_workers = max(
                        10,
                        min(
                            300,
                            calculated_workers
                        )
                    )


                    form["planned_workers"] = (
                        calculated_workers
                    )


                    # ---------------------------------------------
                    # Map road quality to existing model
                    # ---------------------------------------------

                    if (
                        form["road_quality"]
                        == "pichu"
                    ):

                        form["quality_tier"] = (
                            "basic"
                        )

                    elif (
                        form["road_quality"]
                        == "concrete"
                    ):

                        form["quality_tier"] = (
                            "standard"
                        )

                    else:

                        form["quality_tier"] = (
                            "standard"
                        )


            # =================================================
            # VERTICAL STRUCTURE
            # =================================================

            else:

                area_sqft = float(
                    request.form[
                        "area_sqft"
                    ]
                )

                floors = int(
                    request.form[
                        "floors"
                    ]
                )


                if area_sqft <= 0:

                    raise ValueError(
                        "Area must be "
                        "greater than 0."
                    )


                if floors < 1:

                    raise ValueError(
                        "Floors must be "
                        "at least 1."
                    )


                form["area_sqft"] = (
                    area_sqft
                )

                form["floors"] = (
                    floors
                )


                scope_area_sqft = (
                    area_sqft
                )


                form["planned_workers"] = int(
                    request.form.get(
                        "planned_workers",
                        10
                    )
                )


                # Not applicable
                # to buildings

                form["road_quality"] = (
                    "pichu"
                )


            # =================================================
            # CALL EXISTING ML MODEL
            # =================================================

            result = predict_site(

                site_type=form[
                    "site_type"
                ],

                scope_area_sqft=(
                    scope_area_sqft
                ),

                floors=floors,

                planned_workers=(
                    form[
                        "planned_workers"
                    ]
                ),

                city_tier=form[
                    "city_tier"
                ],

                quality_tier=form[
                    "quality_tier"
                ],

            )


            # Make result JSON/template safe

            result = clean_result(
                result
            )


        except Exception as e:

            error = (
                f"Something went wrong: {e}"
            )


    # =================================================
    # RENDER HTML PAGE
    # =================================================

    return render_template_string(

        PAGE,

        form=form,

        result=result,

        error=error,

        site_types=SITE_TYPES,

        city_tiers=CITY_TIERS,

        quality_tiers=QUALITY_TIERS,

    )


# =========================================================
# FLUTTER REST API
# =========================================================

@app.route(
    "/api/predict",
    methods=["POST", "OPTIONS"]
)
def api_predict():

    # -----------------------------------------------------
    # Handle Flutter/browser CORS preflight
    # -----------------------------------------------------

    if request.method == "OPTIONS":

        return jsonify({
            "success": True
        })


    try:

        # =================================================
        # READ JSON
        # =================================================

        data = request.get_json(
            silent=True
        )


        if not data:

            return jsonify({

                "success": False,

                "error":
                    "No JSON data received."

            }), 400


        # =================================================
        # BASIC INPUTS
        # =================================================

        site_type = data.get(
            "site_type",
            "Home"
        )

        city_tier = data.get(
            "city_tier",
            "tier2"
        )

        quality_tier = data.get(
            "quality_tier",
            "standard"
        )

        road_quality = data.get(
            "road_quality",
            "pichu"
        )


        # =================================================
        # VALIDATE SITE TYPE
        # =================================================

        if site_type not in SITE_TYPES:

            return jsonify({

                "success": False,

                "error":
                    f"Invalid site type: {site_type}"

            }), 400


        # =================================================
        # VALIDATE CITY TIER
        # =================================================

        if city_tier not in CITY_TIERS:

            return jsonify({

                "success": False,

                "error":
                    f"Invalid city tier: {city_tier}"

            }), 400


        # =================================================
        # VALIDATE QUALITY
        # =================================================

        if quality_tier not in QUALITY_TIERS:

            quality_tier = "standard"


        # =================================================
        # ROAD / BRIDGE
        # =================================================

        if site_type in LINEAR_TYPES:

            length_m = float(
                data.get(
                    "length_m",
                    0
                )
            )

            width_m = float(
                data.get(
                    "width_m",
                    0
                )
            )


            if (
                length_m <= 0
                or width_m <= 0
            ):

                return jsonify({

                    "success": False,

                    "error":
                        "Length and width "
                        "must be greater than 0."

                }), 400


            # ---------------------------------------------
            # Convert meters → feet
            # ---------------------------------------------

            length_ft = (
                length_m *
                METERS_TO_FEET
            )

            width_ft = (
                width_m *
                METERS_TO_FEET
            )


            # =================================================
            # BRIDGE
            # =================================================

            if site_type == "Bridge":

                scope_area_sqft = (
                    length_ft *
                    (
                        width_ft *
                        0.4
                    )
                )

                floors = 1


                planned_workers = int(
                    data.get(
                        "planned_workers",
                        10
                    )
                )


                if planned_workers < 1:

                    planned_workers = 1


            # =================================================
            # ROAD
            # =================================================

            else:

                scope_area_sqft = (
                    length_ft *
                    width_ft
                )

                floors = 1


                # ---------------------------------------------
                # Same workforce rule as web application
                # ---------------------------------------------

                planned_workers = round(
                    scope_area_sqft /
                    300
                )


                planned_workers = max(
                    10,
                    min(
                        300,
                        planned_workers
                    )
                )


                # ---------------------------------------------
                # Map road quality
                # ---------------------------------------------

                if road_quality == "pichu":

                    quality_tier = "basic"

                elif road_quality == "concrete":

                    quality_tier = "standard"

                else:

                    quality_tier = "standard"


        # =================================================
        # BUILDING / VERTICAL SITE
        # =================================================

        else:

            area_sqft = float(
                data.get(
                    "area_sqft",
                    0
                )
            )

            floors = int(
                data.get(
                    "floors",
                    1
                )
            )

            planned_workers = int(
                data.get(
                    "planned_workers",
                    10
                )
            )


            if area_sqft <= 0:

                return jsonify({

                    "success": False,

                    "error":
                        "Area must be "
                        "greater than 0."

                }), 400


            if floors < 1:

                return jsonify({

                    "success": False,

                    "error":
                        "Floors must be "
                        "at least 1."

                }), 400


            if planned_workers < 1:

                return jsonify({

                    "success": False,

                    "error":
                        "Planned workers "
                        "must be at least 1."

                }), 400


            scope_area_sqft = (
                area_sqft
            )


        # =================================================
        # CALL YOUR EXISTING ML MODEL
        # =================================================

        result = predict_site(

            site_type=site_type,

            scope_area_sqft=(
                scope_area_sqft
            ),

            floors=floors,

            planned_workers=(
                planned_workers
            ),

            city_tier=city_tier,

            quality_tier=quality_tier,

        )


        # =================================================
        # CLEAN MODEL OUTPUT
        # =================================================

        result = clean_result(
            result
        )


        # =================================================
        # EXTRACT RESULTS
        # =================================================

        estimated_cost = result.get(
            "estimated_total_cost_inr",
            0
        )

        estimated_duration = result.get(
            "estimated_duration_days",
            0
        )

        estimated_machines = result.get(
            "estimated_machine_count",
            0
        )

        machine_types = result.get(
            "recommended_machine_types",
            []
        )


        # =================================================
        # RESPONSE FOR FLUTTER
        # =================================================

        return jsonify({

            "success": True,

            "input": {

                "site_type":
                    site_type,

                "area_sqft":
                    scope_area_sqft,

                "floors":
                    floors,

                "planned_workers":
                    planned_workers,

                "city_tier":
                    city_tier,

                "quality_tier":
                    quality_tier,

                "road_quality":
                    road_quality,

                "length_m":
                    data.get(
                        "length_m"
                    ),

                "width_m":
                    data.get(
                        "width_m"
                    ),

            },

            "prediction": {

                "estimated_total_cost_inr":
                    estimated_cost,

                "estimated_duration_days":
                    estimated_duration,

                "estimated_machine_count":
                    estimated_machines,

                "recommended_machine_types":
                    machine_types,

            }

        })


    # =====================================================
    # INVALID INPUT
    # =====================================================

    except ValueError as e:

        return jsonify({

            "success": False,

            "error": str(e)

        }), 400


    # =====================================================
    # SERVER / MODEL ERROR
    # =====================================================

    except Exception as e:

        app.logger.exception(
            "Prediction API error"
        )

        return jsonify({

            "success": False,

            "error":
                f"Prediction failed: {str(e)}"

        }), 500


# =========================================================
# API HEALTH CHECK
# =========================================================

@app.route(
    "/api/health",
    methods=["GET"]
)
def health_check():

    return jsonify({

        "success": True,

        "message":
            "Site prediction API is running.",

        "service":
            "Site Cost / Duration / Machine Estimator",

    })


# =========================================================
# RUN APPLICATION
# =========================================================

if __name__ == "__main__":

    app.run(

        host="0.0.0.0",

        port=5000,

        debug=True

    )