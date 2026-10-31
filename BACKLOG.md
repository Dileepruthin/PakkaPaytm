# Backlog

What is built, what is next, and what is deliberately not being built. The
last of those is the part that usually goes unwritten and then gets argued
about twice.

Ordered by what a judge would notice first, not by what is most interesting
to build.

---

## Done

| | |
|---|---|
| **Lane A — Mandate Radar** | discovery · trajectory · risk model · zombie + drift · remedy ladder |
| **Lane B — In-Flight Resolver** | built, feeding the ledger |
| **Lane C — Expected Inbound** | built, feeding the ledger |
| **Wrong-Person Interceptor** | built — a gate in front of the payment, not a lane |
| **Pakka Balance** | computed in the engine, rendered by the UI |
| **`/demo`** | the instrument panel: every lane and its evidence |
| **`/pitch`** | the argument as a navigable deck, now narrated |
| **`/sim`** | the engine on a handset, stepped through as beats |
| **Narration** | 21 clips, English + Hindi, generated once and committed, captioned on screen |
| **`make dev`** | one command, health-gated so the frontend never races the model |
| **One persona on `/sim`** | the near-miss is an *attempt*, so the user with the shortfall is the user being warned |
| **The deck's opening figures** | lead measured; ~20M / ~95M demoted to a sourced footnote |
| **Hindi, stated** | named as a capability demonstration on `/sim`, in README and on the limits slide |
| **A focus ring, and a contrast target** | one global `:focus-visible`, `-ink` tokens for text, and a written-down number to check against |

### The narration layer

`scripts/narration.py` is the script; `scripts/gen_voice.py` renders it to
`web/public/voice/` through Sarvam `bulbul:v3`. The MP3s are committed, so a
demo needs no API key, no network, and no credit balance. Regenerating is
`make voice`; `make voice-verify` additionally sends every clip back through
speech-to-text and scores the transcript against the script.

Figures spoken out loud are declared on each line and checked by
`pakka/tests/test_narration.py` — against `published_numbers.json` for the
pitch, and against a live API response for the simulation. A stale recording
fails the suite instead of being discovered mid-pitch.

Every clip can also be **read**. A captions switch sits beside the narration
switch on `/pitch` and `/sim` and renders the exact text the manifest holds,
independent of whether audio is playing — gating a transcript behind
playback would withhold it from the people it is for. On `/sim` it follows
the language toggle, so the two Hindi beats caption in Hindi rather than in
an English gloss of them.

`gen_voice.py` states what a run will send before it sends it — clips and
characters, the units Sarvam bills in, rather than a rupee figure this repo
cannot verify — and asks before anything past a couple of clips. A run with
no terminal to ask stops instead of spending; `--yes` is the deliberate way
past that. `--verify` is counted separately because it transcribes every
selected clip, reused ones included.

### The near-miss that was being thrown away

`/sim` used to switch to a second persona for the wrong-person beat, on the
stated theory that only comfortable users have enough money to mistype. That
was wrong. Ramesh listed both decoy contacts all along; his ledger bottoms out
at ₹109.62, and `_safe_to_add` requires the *whole* re-sorted ledger to stay
non-negative, so an ₹18,000 rent-sized debit was rejected wherever it was
placed and the scenario silently vanished — for him, for Sunita, and for
Kavita, who got no scenario at all. The three users under real mandate
pressure were the three the interceptor was never scored on.

A transfer the interceptor catches never settles, which is the whole point of
a gate that runs before confirm; modelling it as a *settled debit* was the
anomaly. It is now injected as a non-settling attempt, so it costs the ledger
nothing and needs no affordability guard. Ramesh's balances are byte-identical
before and after — the hero block in `published_numbers.json` did not move —
and every persona now carries a near-miss.

`build_contacts` gained a `SUCCESS` filter in the same change: a transfer this
gate stopped must not register as a contact, or the second attempt at the same
typo sails through as someone you have paid before.

The re-score that followed is the honest kind. Interceptor precision and
recall held at 100/100 across a larger scenario population and true negatives
rose 109 → 111; the risk model's headline F1 fell 77.4% → 76.3%, while its
false-alarm rate improved 0.8% → 0.7% and its F1 on *contested* cases — the
ones where it actually beats the balance rule — rose 69.6% → 72.7%. The
baseline did not move. Published rather than tuned away.

### The contrast target

There was none, and nothing had been measured. It is now written down in
`globals.css`: WCAG 2.1 AA, 4.5:1 for body text and 3:1 for large text and
non-text UI. Measuring /demo against it found 27 failing text nodes out of
501 — risk-band verdicts (`watch` at 2.17:1, `tight` at 2.97:1) rendered as
words rather than bars, `--money-in` at 3.1:1, and `--color-text-secondary` at
4.49:1 on the muted surface. The `-ink` token pattern the file had already
invented for amber was extended to the rest, and secondary text went one step
darker. Two known exceptions remain, both recorded above and in the CSS.

### The pinned observation date

`OBSERVED_ON` lives in `pakka/eval/publish.py` and every fixture that scores
anything imports it. `generate()` defaults `end` to `date.today()`, so an
unpinned fixture scores a differently-shaped population every calendar day —
that is not hypothetical, it cost a red suite on 18 Aug 2026 when the risk
model's measured precision fell under its floor with no code change behind
it. The constant is imported and never restated: two copies of one pinned
date are two things that can move apart.

---

## Next

### 0. Verify what this sprint committed

Committed on the understanding that it gets checked before it is shown to
anyone. Everything below was verified by machine; none of it was verified by a
person.

- **Nobody has listened to the seven re-recorded clips.** They round-trip
  through speech-to-text at 0.98–0.996 similarity with their figures matched,
  which is a proxy for "the words are right", not for "it sounds right".
  `pitch-problem` and both intercept clips carry expected digit flags —
  ordinals and Hindi numerals are spoken as words, so no digit search can find
  them. Play them once end to end.
- **`pitch-limits` has under a second of margin.** 29.07s against Sarvam STT's
  30s ceiling. It was 32.8s for a while during this sprint and silently lost
  its round-trip check; if that clip grows again, re-measure rather than
  estimate.
- **The re-scored figures are now what the deck says out loud.** Model F1
  76.3%, false alarm 0.7%, contested F1 72.7%, true negatives 111. Worth one
  read-through of `/pitch` and the landing page against
  `published_numbers.json` by eye, because the test only checks that the
  numbers appear in the prose, not that the sentence around them still parses.
- **The contrast pass was scripted.** It measured computed styles on /demo at
  one viewport, in one theme. It cannot see hover states, the mobile layout, or
  anything that only renders after an interaction.

### 1. Finish the public link

Five commits of deploy plumbing landed and then stopped: a Render blueprint,
`vercel.json`, configurable CORS, and a root + HEAD route so Render's health
check stops 404-looping. None of it is verified end to end, and there is no
URL written down anywhere.

Three things are known to be wrong or unknown:

- Render's free plan spins down when idle, so a cold start pays container boot
  **plus** the ~15s `_lifespan` model training. The frontend has no retry — it
  shows an error card that says *"Start both halves with: make dev"*, which is
  the wrong sentence for someone who just clicked a link.
- `pip install -e .` pulling pandas 3.x and scikit-learn, then fitting a model
  at startup, on a 512MB free instance. Untested; OOM is the obvious failure.
- No README section records the deployed URLs.

This is the highest judge-facing value left and the only half-finished thing
in the tree.

### 2. White text on the brand gradient

Found during the contrast pass and deliberately not fixed. `--paytm-gradient`
runs 13.54:1 at the navy stop, 4.88:1 at cyan-mid, and 2.26:1 at pure cyan, so
a white label reaching the far end of a wide pill falls under 4.5:1. Changing
it means restyling the primary CTA, which is a brand decision rather than a
bug fix. Either narrow the gradient's range for text-bearing surfaces, or
accept it and say so.

### 3. The interceptor's control rows still favour the comfortable

Fixed for the near-miss (see Done), not for its control. The genuine
first-time payment is still injected as a settled debit guarded by
`_safe_to_add`, so a user with no headroom does not get one — Kavita gets
neither, and `true_negatives` is measured on a population skewed toward users
with money. Unlike the near-miss there is no clean argument for making it
non-settling: a legitimate first payment really does move money. Probably
wants a size drawn from what the user can actually afford.

### 4. `/demo` has never been walked with a real screen reader

The audit in this sprint was scripted, not spoken: it caught a missing `h1`
and eight unlabelled rings, and it cannot catch reading order, focus traps, or
whether the lane rail makes any sense announced aloud.

---

## Deliberately not doing

**Live TTS in the browser.** Generating narration on demand would mean a
paid API on the critical path of a three-minute pitch, and a key reachable
from the client. The clips are static files for exactly this reason.

**A voice assistant you can talk to.** Sarvam's STT is already wired up and
it would demo well for about ten seconds. It is not what the project is —
the argument is that the *number* is wrong, not that the interface should
be conversational.

**Auto-advancing the deck on clip end.** The manifest has every duration, so
this is easy. It is also how a presenter loses the room: the deck moves while
someone is still answering a question. Advancing stays manual.

**Real bank connectivity, or anything touching real customer data.** The
cohort is synthetic and mechanics-grounded on purpose. Every accuracy figure
in this repo depends on having ground truth, which real statements do not
come with.

**Making the demo's `Confirm` button work.** It is rendered disabled in `/sim`
on purpose. A prototype that looks like it moves money should not be
clickable, even as a mock.

---

## Known limits

Carried from the README and the deck so they sit in one place:

- The NPCI auto-revocation rule is load-bearing and taken from secondary
  sources. The simulator makes it a switch so everything can be re-scored
  under a weaker assumption.
- The industry figures (~20M revocations a month, ~95M active mandates) are
  context, not evidence, and no longer lead anything. Sourcing them was tried
  and failed: the revocation figure traces to press reporting of NPCI data,
  and the ~95M figure traces nowhere — NPCI's own AutoPay ecosystem statistics
  page 404s, and the widely-repeated version carries a companion claim (~4.2
  crore executions a month) that contradicts better-sourced execution counts
  by more than an order of magnitude.
- Hindi is a demonstration of the capability, not a translated product: two
  clips of twenty-one, and an English interface.
- Narration-only discovery recalls 76.4%. Lexical similarity cannot know
  BUNDL TECHNOLOGIES and SWIGGY are one company; that needs a merchant
  directory.
- Most subscription abandonment is invisible to payment data. Those cases
  report `CANNOT_ASSESS` rather than guessing.
- `published_numbers.json` is checked against the prose on every run, but
  nothing checks that the snapshot itself is current — regenerating retrains
  the model, so it stays a deliberate step. Run
  `uv run python -m pakka.eval.publish` to compare without writing.
- This is a prototype on synthetic data, not a production risk system, and
  not affiliated with Paytm.
