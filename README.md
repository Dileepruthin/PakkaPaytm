PakkaPaytm — Forward Obligation Engine
Your balance doesn't know what it already owes.

A payment app shows you one number: Balance: ₹39,267. But that number doesn't know that ₹14,518 of it is already promised to seven standing mandates, that one presents on the 5th while your salary lands on the 7th, that a pending debit from Tuesday hasn't settled yet, or that rent goes out on the 2nd — and no register anywhere has heard of it.

Pakka is the missing primitive: a live ledger of money that is committed but not settled.

text
Pakka Balance =  bank balance
               − committed outflows      (mandates due in horizon)      ← Lane A
               − recurring commitments   (rent and the like, by hand)   ← Lane D
               + expected reversals      (pending debits coming back)   ← Lane B
               + expected inbound        (refunds arriving in time)    ← Lane C
And one gate in front of the payment itself: is this going to the person you meant? — a typo'd VPA, or the wrong Sharma — caught in the seconds before confirm, rather than chased afterwards.

Then one question none of the above asks: why is the money due on that day at all? Every lane moves money to meet a fixed date. The rephaser moves the date.

Built for the Paytm "Build for India" AI Hackathon, Theme 1 — AI for Paytm Users.

Table of Contents
The Problem

System Architecture

The Four Lanes

The Interceptor Gate

The Rephaser

What Paytm Has vs. What Pakka Adds

Measured Results

Data Honesty

Running It

Project Layout

Attribution

The Problem
A bank balance is a point-in-time snapshot. It cannot tell you:

What's already spoken for — mandates, SIPs, EMIs queued before payday

What's in limbo — pending debits that may or may not settle

What's owed to you — refunds that may arrive before — or after — the bill

What you pay by habit — rent, house help, milk vendor: recurring, but invisible to the rail

Under NPCI's UPI AutoPay guidelines, a first-presentation failure revokes the mandate outright — it does not retry. Ramesh, the headline persona, has four mandates presenting on the 5th and salary landing on the 7th. He is short for two days of every single month. When a debit fails, it isn't a late payment — it's a SIP, insurance premium, or EMI that silently died over a few hundred rupees on the wrong morning. Most people find out months later.

On industry figures. Earlier drafts led with ~20M revocations/month and ~95M active mandates. Both are secondary and kept as context only. The revocation figure is press reporting; the 95M figure could not be traced to a primary source (NPCI's AutoPay stats page currently 404s). Nothing in this project rests on them. Every figure argued here is measured on a synthetic cohort and reproducible with one command.

System Architecture















Read it in three moves:

Raw statements enter Discovery. Entity resolution collapses noisy narrations into payees; periodicity detection finds the recurring rhythm.

Four lanes net into one number — the Pakka Balance. Two subtract (Lane A mandates, Lane D manual commitments), two add (Lane B reversals, Lane C refunds). The math is signed and explainable.

A graduated ladder acts on the result — notify → resequence → credit → revoke.

Two components deliberately sit outside that path:

Component	Why it's separate
Interceptor	A gate in the seconds before confirm — never touches the ledger
Rephaser	Reshapes the debit calendar the lanes are computed against — not a lane, not a ladder rung (a mandate can't be modified within 2 days of presenting; the ladder speaks 24 hours out)
The Four Lanes
Each lane is a signed contribution to the Pakka Balance. Two subtract, two add.

Lane A — Mandate Radar (− Outgoing)
Finds scheduled AutoPay obligations, projects their trajectory, flags shortfalls, and detects zombie mandates (no longer active) and amount drift (electricity, card autopay).

Lane B — In-Flight Resolver (+ Possible reversal)
Interprets a debit that is still pending. The failure that matters here is double payment — so when settlement and reversal genuinely overlap, the honest verdict is "wait". Hedges on the rest.

Lane C — Expected Inbound (+ Eligible credits)
Estimates whether a pending refund will arrive inside the forecast horizon. A statement can't see a cancelled order — only the refund it triggered — so that's all this lane claims to see. Late money is not guaranteed money.

Lane D — Recurring Commitments (− Planned spending)
Rent, house help, milk vendor, school fees — paid by hand, every cycle, in no register anywhere. Distinguishes a habit from a mandate, because warning someone their rent "will be revoked" is a false alarm.

The Interceptor Gate
Not a lane. A gate in front of the payment answering a different question:

Not "will this debit clear" — but "is this going to the person you meant?"

Novelty is never the alarm. Paying someone for the first time is completely ordinary — a new landlord, splitting a bill with someone you just met. A first-time payee caps at the mildest rung at any amount. Escalation requires evidence of a specific alternative: a VPA one edit away from someone you already pay, or a name that resolves to a different saved contact.

It's rules, not a model — deliberately. Mandate failure is a weak-signal problem across thousands of noisy presentations and earns gradient boosting; "this VPA is one character off one you pay every month" is close to deterministic and must be explainable in the second before someone taps confirm.

The Rephaser
Every remedy above moves money to meet a fixed date: notify, pause something cheap, borrow, cancel. The debit date is treated as a constant of physics.

It isn't. It's a field in a registration record. NPCI permits in-place modification of a live AutoPay mandate's debit date — no re-registration, subject to UPI PIN re-authorisation — and Paytm's own AutoPay docs name this exact use case.

The headline persona isn't poor. Ramesh has ~₹10k a month of slack and still risks losing a SIP every month. He's not short of money — he's out of phase. Merchants pick the 1st, 5th, 10th; employers pick the 1st, 7th, 30th. Neither consults the other.

Two clocks, deliberately separate
Asks	Fires
The ladder	"This debit is about to fail — what now?"	24h out, and again every month
The rephaser	"Is this calendar the right shape?"	Whenever nothing is about to fail — once
A mandate cannot be modified within 2 days of presenting, and the ladder fires inside the 24-hour pre-debit window — so at the moment the ladder speaks, moving the date is already illegal. Adding rephase as a ladder rung would be a bug. tests/test_phase.py asserts there is no reschedule rung.

What Paytm Has vs. What Pakka Adds
Paytm — like every UPI app — already has a mandate registry: list, pause, revoke. This is not that.

Paytm has	Pakka adds
Mandate registry (list / pause / revoke)	Forward-projected obligation calendar
Point-in-time balance	Shortfall prediction against that calendar
Pre-debit notifications (pass-through)	Zombie and amount-drift detection
Transaction history (the past)	In-flight settlement inference
—	One number that nets all of it
A registry tells you what exists. An engine tells you what is about to happen.

Measured Results
All figures below are measured on a synthetic cohort and regenerable with one command (see Reproducing Every Figure).

Lane A — Mandate Discovery
Scored against ground truth across a 30-user cohort:

Resolution path	Precision	Recall
with payee VPA	100.0%	100.0%
narration only	100.0%	76.4%
Zero false positives on both paths. Precision is tuned ahead of recall deliberately — a false "your SIP will fail" destroys trust faster than a miss. The narration-only gap is real (lexical similarity can't know BUNDL TECHNOLOGIES and SWIGGY LIMITED are the same company — that needs a merchant directory, not a better string metric).

Death-Risk Model
150-user cohort, split by user (not event) — presentations from one person are too correlated for an event split. Scored 24 hours ahead of each debit, inside the pre-debit notification window:

Precision	Recall	F1	False alarms
Model	78.1%	74.6%	76.3%	0.7%
Naive balance rule	58.6%	76.1%	66.2%	1.7%
The naive rule is strong almost by construction — a balance rarely moves far in a day. So the comparison that decides whether the model earns its complexity is the contested band (balance a day out sits within 0.5×–2× of the amount due and the next 24 hours actually settle it):

Contested cases only (58 presentations)	F1
Model	72.7%
Naive balance rule	63.6%
An earlier version scored ROC AUC 1.000. That was target leakage — features read the balance at the instant of presentation, and a debit fails exactly when that balance is short: the feature was the label. Scoring from 24h out fixed it — and is also the product, since the notification window is the only moment anything can still be done. tests/test_risk.py asserts truncating the statement at the observation point leaves every feature vector unchanged.

Lane B — In-Flight Resolver
text
Decisive            109 of 955 probes   accuracy 100.0%
False "safe to pay again"    0 (0.00%)  ← the error that causes a double payment
It hedges on the rest, and that's the point. A 7-hour settlement window is decisive far more often (282 calls) but produces 46 double payments; from 10 hours upward that error is zero. 12 was chosen — fewer confident answers, no double payments.

Lane C — Expected Inbound
text
Promised into Pakka Balance   ₹241,130
Actually arrived in time      ₹253,755
OVER-promised   19.8% of what was promised   ← the error that kills a mandate
The error asymmetry is the opposite of Lane B's. Lane B must never say a payment failed when it settled. Here the expensive mistake is counting money early: a refund promised into today's spendable balance that lands on the 12th can leave a mandate short on the 5th — and a first-presentation failure revokes it outright. So each refund is counted only in proportion to how likely it is to land inside the horizon. In aggregate the lane promises less than arrives — the safe direction.

Lane D — Recurring Commitments
text
Identification   precision 100.0%   recall 100.0%
Mandates misread as commitments   0   ← anything above zero is money counted twice
Mean error per window   ₹1,488   vs   ₹3,392 for a flat daily rate
A habit is not a weaker mandate — it's uncertain in both axes, and the lane reports both. A mandate has a debit day; a habit has a window. A mandate presents unless revoked; a habit presents if the person gets round to it. Both multiply into the reserve.

The trap the lane exists to avoid is double-counting time. Rent lands on the 3rd; the engine observes on the 4th. Projecting "due on the 3rd, which is this month" would subtract money the bank balance already reflects. The next due date comes from last payment + one cadence, never the modal day alone.

Reserving the median would be the wrong number. A landlord paid in two instalments shows a median of half the rent. The lane reserves what a cycle costs — everything the payee has taken over the cycles it was paid in.

The comparison that justifies building it. Spreading the same spend as a flat daily rate is less than half as accurate per window (₹3,392 vs ₹1,488) — it reserves a little on every day instead of the right amount on the few days it's owed. But on aggregate coverage the flat rate scores better (220.8% vs 71.2%): its errors all point the same way, so they sum to something that looks close while every individual window is wrong. Both figures are published, because either alone misrepresents which model is nearer the truth.

Verified Remedies
The ladder used to prove its own advice by arithmetic: pausing a ₹649 mandate frees ₹649, which covers a ₹640 gap. True — and not enough. The gap is measured against a projected balance, and the projection is a consequence of the very schedule the remedy is rearranging.

So every resequence is now applied to a copy of the world and re-scored. If the model doesn't agree the danger has passed, the rung is not offered — it falls through to the next one.

A deferral moves a debit; it does not delete one. Modelling a pause as deletion lets a remedy look free — the money stops being owed instead of being owed later.

What is beyond the horizon is dated, never scored. A monthly deferral lands ~30 days out; FORECAST_HORIZON_DAYS is 10 precisely because past that the projection is arithmetic dressed up as a forecast.

The ladder now solves every short day, not only the worst.

Rephase — Scored Against Ground Truth
Each user's month is replayed twice from the same opening balance and statement — once on the days mandates actually sat, once on the days the engine proposes. Every salary, payment, and timestamp is held fixed. Only the morning each mandate lands on changes.

text
Replay fidelity          100.0%   (89 of 89 real deaths reproduced on unchanged calendar)
Addressable deaths           89
Unaddressable deaths         38   ← notification / bank-side; no calendar fixes these
Prevented                    17   (19.1% of addressable)
Introduced                    5   ← the error that matters
Net                          12
Value saved             ₹50,491
One in five, not most. An earlier framing claimed most autopay deaths are a scheduling bug rather than a poverty problem. On this cohort, about a fifth come off the board by moving dates alone; the rest are people who genuinely didn't have the money on any day of the month. The smaller claim is the one that survived being measured.

Newly introduced deaths are reported beside prevented ones, never netted into them. An earlier optimiser prevented nine deaths while causing nine others — a net of zero only the introduced column made visible.

Data Honesty
Everything here runs on a synthetic, mechanics-grounded cohort. No real customer data is involved, and none was used.

The simulator models the mechanics that actually govern this problem — NPCI presentation and revocation, the 24-hour pre-debit notification (and its own failure mode), morning-batch clustering, re-registration after a death — and produces statements that are hard in the ways real statements are hard:

Mandates hidden inside heavy discretionary noise (~2% of lines)

One merchant appearing under many narration strings

Steady dates with unsteady amounts (electricity, card autopay)

Decoys: rent and house help — periodic-looking, but not mandates

Collisions: several mandates stacked on one day, ahead of payday

Refunds issued and then arrive slowly, or never

A typo'd transfer to a VPA one character off a real contact — alongside perfectly ordinary first-time payments that must not be flagged

Ground truth lives on the cohort, never on the statement the engine reads. Every run is seeded, so published numbers are reproducible by a third party.

On the research artifacts
.archive/study.html and .archive/web.html are an early scan of the Paytm AI space, kept for the reasoning trail. They are not this project's claims — the idea they argue for is not the one built, and three figures didn't survive verification: ₹48,021 Cr is total bank fraud (not digital), the 99.5% voice-accuracy claim couldn't be reproduced, and the 547-store survey has no nameable source. Each file opens with a banner saying exactly that, and both are filed under .archive/ so nobody meets them before the work. Marked and moved rather than deleted — quietly removing evidence of a wrong turn is a worse habit than labelling it.

Reproducing Every Figure
One command regenerates all of them:

bash
cd pakka && uv run python -m pakka.eval.publish
It prints every figure quoted here and on the landing page. Add --write to refresh pakka/published_numbers.json, the committed snapshot they're checked against.

That check is enforced, not a convention. tests/test_published_numbers.py parses figures out of this file and the landing page and fails if either disagrees with the snapshot — because prose drifts silently, and it already has.

Running It
bash
make install && make dev
make dev starts the engine, waits until it actually answers, and only then brings up the interface. The wait isn't padding: the API trains the risk model before serving its first request — so the first click of a demo isn't the one paying for it. Starting both at once races that, and the interface loses.

The halves separately:

bash
cd pakka && uv sync && uv run uvicorn pakka.api.main:app --port 8011
bash
cd web && npm install && npm run dev
Set NEXT_PUBLIC_PAKKA_API in web/.env.local if the API isn't on port 8011.

Run the tests:

bash
cd pakka && uv run pytest
Every published figure:

bash
cd pakka && uv run python -m pakka.eval.publish
Individual lanes (full scorecard with false positives and misses):

bash
cd pakka && uv run python -c "
from datetime import date
from pakka.sim.cohort import generate, CohortConfig
from pakka.eval import discovery, risk, anomaly, inflight, inbound, interceptor, phase

OBSERVED_ON = date(2026, 8, 4)
main = generate(CohortConfig(users_per_persona=30), end=OBSERVED_ON)
print(discovery.report(generate(CohortConfig(users_per_persona=6), end=OBSERVED_ON)))
print(risk.report(main))
print(anomaly.report(generate(CohortConfig(users_per_persona=1), end=OBSERVED_ON)))
print(inflight.report(main))
print(inbound.report(main))
print(interceptor.report(main))
print(phase.report(main))
"
⚠️ The observation date has to be pinned. Left out, the cohort is generated against today — a different cohort producing different numbers (Lane B, for instance, scores 901 probes rather than the published 955). An earlier version of this section omitted it, so the commands the README gave you didn't reproduce the figures the README quoted.

The Narration
The deck and phone simulation are spoken, in English and — for the two moments where not understanding the sentence is what costs you money — in Hindi. Sarvam's bulbul:v3 renders them; an Indian model for an India-first product is the plain choice.

The Hindi is a demonstration of the capability, not a translated product. Two clips of twenty-one are Hindi; no screen of the interface is. That's a defensible scope for a prototype — and would be indefensible for anything shipping under "built for India" — so it's stated here, on /sim, and on the deck's limits slide. The two that exist are the balance and the interception, on the reasoning that if only two sentences can be understood, they should be the ones where misunderstanding costs money.

Clips are generated once and committed to web/public/voice/. Nothing at runtime calls Sarvam. A pitch that reaches a paid API on stage has two ways to fail at the exact moment neither can be debugged, and it would put a key somewhere the browser could read it.

bash
make voice          # render whatever changed
make voice-verify   # ...and transcribe each clip back, scoring it
The script lives in scripts/narration.py as text — because an MP3 cannot be diffed, grepped, or reviewed, and a stale sentence inside one is audible exactly once, to the room, during the pitch. Every line that states a figure declares which figure it states; tests/test_narration.py checks those declarations against published_numbers.json for the deck and against a live API response for the simulation.

--verify sends each clip back through speech-to-text. It's how 76.3% and ₹9,307 were confirmed to be read correctly rather than assumed — and how "naive" was caught being spoken as "Nai" and reworded to "plain balance rule".

Project Layout
text
pakka/                 the engine
  models.py            domain vocabulary
  sim/                 cohort generator + merchant catalogue
  discover/            entity resolution, periodicity detection
  forecast/            inflow detection, balance trajectory
  risk/                point-in-time features, death-risk model
  anomaly/             zombie + amount-drift detection
  remedy/              the graduated remedy ladder, and verification of it
  inflight/            Lane B — has this pending debit settled?
  inbound/             Lane C — will this refund arrive in time?
  phase/               Rephase — is this calendar the right shape?
  interceptor/         wrong-person transfer gate
  ledger/              the Pakka Balance identity
  eval/                scoring against ground truth
  api/                 FastAPI surface

web/                   Next.js 16 + React 19 + Astryx
  app/page.tsx         landing page
  app/demo/            the live engine — every lane at once
  app/pitch/           the argument as a deck, narrated
  app/sim/             the engine on a handset, stepped through
  theme/paytm.ts       Paytm brand theme
  components/          ConfidenceRing, StatementScan, SeriesRow,
                       RiskTimeline, InflightPanel, InboundPanel,
                       TransferInterceptor, LaneDiagram, CountUp, VoiceToggle
  public/voice/        the generated narration, committed

scripts/               every spoken line, and what renders it
The interface follows the design system's own conventions: rows rather than Card-wrapped list items, Token for status and Badge only for counts, and tokens instead of hardcoded values.

On the observation date
Mandate risk is real but not present on every calendar day — it depends where each user sits in their own cycle. The demo observes from 4 August 2026, where Ramesh is one day out from four mandates presenting together and three days short of payday, while comfortable personas stay comfortable. The date is pinned so the demo is reproducible; the behaviour was checked by sweeping it.

On explanations
evidence is an engine output, not interface copy. The engine emits the reasons behind each verdict as prose, and the UI renders those sentences verbatim. An explanation invented next to the data is indistinguishable from one grounded in it — right up until they disagree.

The animation does the same job. StatementScan replays the actual normalisation step: raw narrations arrive, reference numbers and rail/bank tokens strike through, and what survives collapses into one payee. It shows entity resolution happening rather than asserting that it did.

Attribution
Built with Astryx, Meta's open-source design system. Paytm publishes no official design-system package, so the brand theme is derived from public brand marks and product surfaces.

⚠️ This is a hackathon prototype. It is not affiliated with, endorsed by, or a product of Paytm.
