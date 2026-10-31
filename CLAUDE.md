# Pakka — Forward Obligation Engine

Built for the Paytm "Build for India" AI Hackathon, Theme 1 (AI for Paytm
Users). Full argument and product framing: [README.md](README.md). Planning
history that diverged from what got built: [hid.md](hid.md) — read the
warning banner at its top before trusting anything below it.

Two halves, run together:

```
pakka/   Python 3.13 + FastAPI engine (uv-managed)  → localhost:8011
web/     Next.js 16 + React 19 + Tailwind v4 frontend → localhost:3000
```

## Running it

```bash
make install   # uv sync + npm install, both halves
make dev       # backend in background, waits for it to be healthy, then frontend
```

`make dev` is the one to use for a pitch or demo. The backend's `_lifespan`
hook (`pakka/src/pakka/api/main.py`) trains the risk model on startup —
roughly 15s — so the *first click* isn't the one paying for it. Starting the
backend and immediately switching to the frontend races that training and
shows a dead page; `make dev` polls `/api/users` until the engine actually
answers before bringing the frontend up. `make backend` / `make frontend` run
either half alone; `make stop` kills a backgrounded backend; `make help`
lists everything.

```bash
cd pakka && uv run pytest                    # engine test suite
cd pakka && uv run python -m pakka.eval.publish   # recompute published figures (prints; --write to save)
make voice                                   # re-render changed narration clips
make voice-verify                            # ...and transcribe them back to check
```

`tests/test_published_numbers.py` fails the suite if the figures in
README.md / the landing page drift from that snapshot — treat a failure
there as the prose being wrong, not the test.

## Layout

```
pakka/src/pakka/
  models.py       domain vocabulary
  sim/            cohort generator + merchant catalogue
  discover/       entity resolution, periodicity detection
  forecast/       inflow detection, balance trajectory
  risk/           point-in-time features, death-risk model
  anomaly/        zombie + amount-drift detection
  remedy/         graduated remedy ladder + verification (ladder.py, verify.py)
  commitments/    Lane D — rent and the like, paid by hand, in no register
  inflight/       Lane B — has this pending debit settled?
  inbound/        Lane C — will this refund arrive in time?
  phase/          Rephase — is this calendar the right shape? (not a lane)
  interceptor/    wrong-person transfer gate
  ledger/         the Pakka Balance identity (computed here, not in the UI)
  eval/           scoring against ground truth
  api/            FastAPI surface (main.py)
web/src/
  app/layout.tsx  the chrome — PaytmNav and SiteFooter, mounted once for
                  every route. Pages render no navigation of their own.
  app/globals.css every design token, plus the @theme bridge that gives
                  them Tailwind utility names
  app/page.tsx    landing page
  app/demo/       the live engine — every lane at once
  app/pitch/      the pitch deck, narrated
  app/sim/        the engine on a handset, stepped through as beats
  components/     PaytmNav, LaneRail (the /demo lane + persona bar),
                  NextStep (the handoff at the foot of each page),
                  SiteFooter, PakkaBalanceHero, ConfidenceRing,
                  StatementScan, SeriesRow, RiskTimeline, InflightPanel,
                  InboundPanel, CommitmentsPanel, TransferInterceptor,
                  LaneDiagram, CountUp, Reveal, VoiceToggle
  lib/api.ts      typed client for the Pakka engine
  lib/voice.ts    playback for the pre-generated narration
  lib/useSectionSpy.ts  which /demo section is in view; drives the lane rail
scripts/
  narration.py    every spoken line, with the figures it claims
  gen_voice.py    renders it to web/public/voice/ via Sarvam bulbul:v3
```

`web/` has its own [CLAUDE.md](web/CLAUDE.md) and
[AGENTS.md](web/AGENTS.md) covering the Tailwind CSS + CSS custom properties
design system conventions (no raw hex values, tokens for everything, premium UI) — read those
before touching frontend code.

## Conventions worth knowing before editing

- **The header lives in `app/layout.tsx`, once.** Pages must not mount
  `<PaytmNav/>` themselves — every one of them used to, which is how a page
  could silently end up with no navigation. The header carries *page
  destinations only*: no `#fragment` links. That is not cosmetic — the moment
  it carries /demo's fragments it needs /demo's scroll-spy state, which is
  what stopped it living in a layout before.
- **/demo has exactly two sticky bars**: the header, and `LaneRail`. It had
  three. If you add a title band, take one away.
- **Panel padding uses `--pad-section` / `--pad-panel` / `--pad-inset`**, not
  literals. /demo nests panels four deep and those three tokens tighten
  together below 680px; a hardcoded padding in that chain reintroduces the
  91px-of-gutter-on-a-phone problem.
- **A CSS module that animates a keyframe must declare that keyframe.** CSS
  Modules rewrites `animation-name` to a per-file hash whether or not the file
  declares it, so hoisting a shared `@keyframes` into globals.css silently
  kills the animation. This was tried; it does not work.
- **The rephaser is not a rung on the remedy ladder, and must not become
  one.** A mandate cannot be modified within 2 days of its next presentation
  ([phase/rephase.py](pakka/src/pakka/phase/rephase.py)), and the ladder fires
  inside the 24-hour pre-debit window — so at the moment the ladder speaks,
  moving the date is already illegal. A reschedule rung would be a button that
  cannot be pressed. The ladder may *name* the structural cause via the
  optional `rephase=` argument to `recommend()`; it may not offer it.
  `tests/test_phase.py` asserts no such rung exists.
- **The rephaser is fitted and scored on different months.** `propose(...,
  fit_before=)` restricts the fit; `eval/phase.py` scores the months after it.
  Without the split the optimiser picks dates to fit the very failures it is
  then credited with preventing. Production calls `propose()` with no
  `fit_before` and uses everything available — that is correct, and only the
  eval needs the split.
- **Pakka Balance is computed by the engine**, in
  [pakka/src/pakka/ledger/pakka.py](pakka/src/pakka/ledger/pakka.py), never
  re-derived in the frontend. An earlier version summed historical medians
  client-side; it was wrong and in the wrong layer. Don't reintroduce that.
- **A deferral moves a debit, it never deletes one.** `remedy/verify.py` builds
  the counterfactual by shifting `DebitEvent.scheduled_for`, not by dropping
  the event — modelling a pause as a deletion is what makes a remedy look free
  and hides the collision it creates next cycle. It also returns a *copy*: the
  API hands the same `lru_cache`d `Cohort` to every endpoint, so mutating it
  would rewrite the world for every later request.
- **Never attach a probability to a landing beyond the horizon.**
  `LandingPoint.scored` is False past `FORECAST_HORIZON_DAYS`, and
  `probability` is `None` there. The date is certain; the outcome is not.
- **Lane A and Lane D must never carry the same series.** Lane A counts
  registered mandates; Lane D counts recurring payments made by hand. A series
  in both subtracts the same money twice, so `is_commitment` treats
  `DiscoveredSeries.is_mandate` as a hard exclusion, and
  `tests/test_commitments.py` asserts it against the whole cohort rather than
  a fixture. Relatedly, do not gate Lane D on `DiscoveredSeries.confidence` —
  that score measures *mandate-ness*, and rent scores low precisely because it
  is hand-paid.
- `web/.env.local` sets `NEXT_PUBLIC_PAKKA_API` (default
  `http://127.0.0.1:8011`) — the frontend has no fallback logic for a
  missing backend; it's a dead page with a console error until the API
  answers.
- The demo observes from a pinned date (`OBSERVED_ON` in `api/main.py`) so
  the scenario (mandates colliding, one persona near a shortfall) stays
  reproducible across restarts. Don't "fix" it to `date.today()`. The same
  applies in reverse to tests: `generate()` defaults `end` to today, so any
  fixture that scores accuracy must pass `end=OBSERVED_ON` or it will fail on
  whichever calendar day the population happens to shift under the threshold.
- Narration is generated once and committed. The demo plays static MP3s and
  never calls Sarvam, so `SARVAM_API_KEY` is needed only to re-record — and
  it must stay un-prefixed in `web/.env.local` so Next never ships it to the
  browser. Figures spoken aloud are declared in `scripts/narration.py` and
  checked by `pakka/tests/test_narration.py`; edit the script and re-run
  `make voice`, never the manifest by hand.
