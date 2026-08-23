# Construction Cost Estimator — Backend + Flutter Integration

## 1. Test locally

```bash
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Verify it's alive:
```bash
curl http://localhost:8000/
curl -X POST http://localhost:8000/predict/house -H "Content-Type: application/json" \
  -d '{"built_up_area_sqft":1500,"floors":2,"quality_tier":"standard","city_tier":"tier2","structure_type":"RCC_frame","foundation_type":"normal"}'
```
Interactive API docs are auto-generated at `http://localhost:8000/docs`.

## 2. Deploy the API

Pick one — all have free/cheap tiers suitable for a small model API:

- **Railway** (railway.app) — easiest: connect your GitHub repo, it auto-detects `requirements.txt`, deploys in a few minutes.
- **Render** (render.com) — similar flow, free tier available (may cold-start after inactivity).
- **Fly.io** — a bit more setup (needs a Dockerfile) but fast and cheap once running.

Whichever you pick, make sure:
- The `models/` folder (containing the two `.joblib` files) is included in the deploy — it's not optional, the API loads them on startup.
- You get back a public HTTPS URL, e.g. `https://your-app.up.railway.app`.

**Security note:** `main.py` currently allows CORS from `*` (any origin) for easy testing. Once deployed, restrict `allow_origins` in `main.py` to your actual domains, and consider adding a simple API key check if this will be publicly reachable.

## 3. Wire up Flutter

1. Copy the three `.dart` files into your Flutter project (e.g. `lib/services/` and `lib/models/`).
2. Add to `pubspec.yaml`:
   ```yaml
   dependencies:
     http: ^1.2.0
   ```
   then `flutter pub get`.
3. In `house_cost_estimate_screen.dart`, replace:
   ```dart
   final _service = CostEstimateService(baseUrl: 'https://your-api-domain.com');
   ```
   with your deployed URL. Don't hardcode this in a real app — inject it via `--dart-define=API_BASE_URL=...` or a config file so you can point at localhost during dev and production once shipped.
4. **Local testing on an emulator**: Android emulators can't reach `localhost` directly — use `http://10.0.2.2:8000` instead. iOS simulator can use `http://localhost:8000` directly. A physical device needs your machine's LAN IP (e.g. `http://192.168.1.x:8000`), with phone and computer on the same network.

## 4. Add the road estimator screen

`house_cost_estimate_screen.dart` is a full example. For the road estimator, follow the same pattern but call `_service.estimateRoad(RoadEstimateRequest(...))` instead — the models and service class already support it, only a new screen needs to be built.

## 5. When you have real job data

Retrain `house_cost_model.joblib` / `road_cost_model.joblib` with real logged costs (see `train_final_models.py` from earlier), then just replace the two files in `models/` and redeploy — no API or Flutter code changes needed, since the input/output shape stays the same.
