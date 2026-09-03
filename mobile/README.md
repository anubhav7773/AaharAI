# AaharAi mobile configuration

Flutter reads these public build inputs at compile time; it does not
automatically load `.env.example` or any dotenv file:

- `API_BASE_URL` — backend HTTP(S) URL. It defaults to the deployed backend
  (`https://aaharai-backend.onrender.com`), so a phone build can reach it.
- `SUPABASE_URL` — public Supabase project URL.
- `SUPABASE_ANON_KEY` — public/anonymous Supabase key.

The two Supabase values are required for authentication. If they are omitted,
the app now opens a configuration screen instead of closing during startup.

## Run locally

```bash
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000 \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-public-anon-key
```

Use the same keys for a release build:

```bash
flutter build apk \
  --dart-define=API_BASE_URL=https://api.example.com \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-public-anon-key
```

`GEMINI_API_KEY` and `SUPABASE_SERVICE_ROLE_KEY` are backend-only secrets.
They never belong in mobile configuration or `--dart-define` arguments.
