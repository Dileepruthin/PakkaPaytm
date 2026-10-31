# Paytm AI Hackathon — Theme 1 (AI for Paytm Users): Idea Selection & Build Plan

---

> ### ⚠️ This is the plan, not the build. They diverged.
>
> Kept for the reasoning trail. Read `README.md` for what exists and the
> `/pitch` deck for the argument as it is actually made.
>
> **What was built is idea #3 from this document's own shortlist** — the
> autopay shortfall predictor — not idea #1. "Kavach", the adaptive friction
> engine this plan spends most of its length arguing for, was never built,
> and neither was the Phase 2 agent-authorization layer. The wrong-person
> transfer interceptor that *was* built is a narrow slice of #1/#4
> territory: pre-confirm payee checking only, with no fraud scoring, no
> coercion detection and no trusted-person rail.
>
> Two things in here are wrong on their own terms:
>
> - The Context section below says the macro numbers in `study.html` /
>   `web.html` "hold up". **Part 9 of this same document then contradicts
>   that**, flagging three of them for removal. Part 9 is the correct one;
>   both artifacts now carry a banner saying so.
> - The 1–2 week solo timeline and the Phase 1/Phase 2 sequencing describe an
>   intended shape of work, not what happened.
>
> What this document got right and is worth keeping for: the framing of
> precision over recall, the insistence on scoring against ground truth
> rather than demonstrating, and the instruction to scrub borrowed
> statistics before pitching. Those became the spine of the project.

---

## Context

You have two research artifacts (`study.html`, `web.html`) mapping the Paytm AI hackathon space. The macro numbers hold up, but they were assembled against a 2025 snapshot and several things shifted in 2026 that reorder which consumer-side idea is worth building.

You've chosen **Theme 1 — AI for Paytm Users**: *"intelligent AI experiences that improve speed, trust, and personalization... payments and financial interactions smarter, simpler, and safer."*

That theme sentence turns out to describe an actual, live, unresolved policy fight in Indian payments right now. This plan builds directly into it.

**Your constraints (confirmed):** solo, backend/data pipelines is your strongest axis, 1–2 weeks of build time, high-conviction idea first with the frontier agentic layer on top.

---

## Part 1 — The opening: a real fight, happening now

On **9 April 2026** the RBI published a discussion paper, *"Exploring safeguards in digital payments to curb frauds."* Comments closed 8 May 2026; final guidelines are pending. It proposes:

1. **Lagged credit** — P2P transfers above ₹10,000 to a newly added beneficiary held up to one hour. Sender debited instantly, credit held.
2. **Trusted-person authentication** — senior citizens (70/75+) and persons with disabilities can nominate a family member to approve transfers above ₹50,000.
3. **Mule-account controls** — ~₹25 lakh/year inbound cap on inadequately verified accounts.
4. **Customer-activated kill switch** — instantly disable digital payments.
5. **Whitelisting** — trusted beneficiaries exempt from delay.

The industry pushed back hard. Bankers warned it would disrupt the ecosystem and hit time-sensitive payments — medical emergencies, vendor payouts, tax, property. The sharpest criticisms were two:

> Making rules that treat **every user as a potential victim** is not appropriate.

> Fraudsters can simply **bypass the threshold by splitting into smaller transfers**.

Both criticisms are correct, and both are arguments *for AI rather than against safeguards*.

### The thesis

**A blanket rule is a blunt instrument. It taxes ~100% of legitimate high-value payments to catch a small fraction of fraud, and a structuring fraudster walks straight around it.**

The intelligent version doesn't ask *"is this over ₹10,000?"* It asks *"is this transaction, for **this** user, consistent with how they actually behave — and does it carry the signature of coercion?"* Then it applies the **minimum friction that the risk justifies**.

That is precisely the theme's three words, and they are normally in tension:
- **Speed** — the ~97% of legitimate payments stay instant, no cooling-off, no delay.
- **Trust** — real coercion patterns get caught, including the structuring that threshold rules miss entirely.
- **Personalization** — friction calibrated to *this* user's baseline and vulnerability, not a national constant.

You are not proposing to slow payments down. **You are proposing the thing that lets India keep instant payments while still getting the safety RBI wants.** That is a genuinely strong pitch, and it is a scoring/data problem — your exact strength.

---

## Part 2 — What your existing research is missing

Four consumer-relevant shifts absent from `study.html` / `web.html`:

1. **The RBI April 2026 discussion paper above.** This is the centre of gravity for consumer trust right now and it isn't in your files.
2. **NPCI's Unified Agent Protocol (UAP)** — as of July 2026, NPCI is building a framework to register, verify and authorise AI agents to transact on UPI with spending limits, merchant scoping, audit trails and revocation. Not launched; needs RBI approval. Builds on UPI Circle's delegated-payments rail, which was already extended to IoT devices *and software profiles* by NPCI circular in Oct 2025. This is the biggest whitespace in Indian fintech and it is Theme-1 territory.
3. **Paytm already ships agentic developer infrastructure** — MCP Server, Agent Skills, an n8n node, and an AI Router, with sandbox access to PG, Payouts, Payment Links, Subscriptions and Disputes.
4. **Scale of the autopay problem** — 850M cumulative UPI AutoPay mandates, ~95M active, ~4.2 crore debits/month, and ~20M revocations *per month* triggered by insufficient balance.

**One correction to carry into your pitch:** the ₹48,021 Cr figure in your research is *total bank fraud*, not UPI/digital payment fraud. RBI's own paper cites roughly ₹35,000 Cr of digital fraud in FY25. Use the right number for the right claim — technical judges will catch a mismatched statistic, and it costs you more credibility than the bigger number buys.

---

## Part 3 — Ranked Theme 1 shortlist

Scored 1–5. **Gap** = real, new, unserved. **Fit** = Paytm strategic alignment. **Solo** = buildable by one backend engineer in 1–2 weeks. **Demo** = lands in 3 minutes. **Moat** = hard to copy in the room.

| # | Idea | Gap | Fit | Solo | Demo | Moat | Total |
|---|---|---|---|---|---|---|---|
| **1** | **Adaptive friction engine** — personalized alternative to RBI's blanket delay | 5 | 5 | 5 | 5 | 5 | **25** |
| **2** | **Agent authorization layer** (UAP-anticipating) — Phase 2 of #1 | 5 | 5 | 4 | 5 | 4 | 23 |
| 3 | Autopay shortfall predictor → credit at the moment of failure | 4 | 5 | 5 | 3 | 2 | 19 |
| 4 | Fraud-recovery co-pilot (golden hour, 1930/NCRP auto-filing) | 4 | 3 | 4 | 4 | 2 | 17 |
| 5 | Voice-deepfake / vishing detector | 4 | 4 | 1 | 3 | 1 | 13 |
| 6 | Generic "AI financial assistant" / spend chatbot | 1 | 3 | 5 | 2 | 1 | 12 |

**#1 and #2 are one product in two phases** — which matches your stated posture exactly. The key realisation that unifies them is in Part 4.

**Avoid #5** — you cannot out-model Paytm's risk team in two weeks, and the 99.5% accuracy figure in your research comes from papers you can't reproduce on stage. **Avoid #6** — every hackathon has six of them.

---

## Part 4 — The build: **"Kavach"** — an adaptive trust layer for Paytm payments

*(working name; "armour")*

### Pitch
> RBI wants to delay every UPI transfer over ₹10,000 to catch fraud. That would slow down millions of legitimate payments — and a fraudster just splits the amount and walks around it. Kavach decides *per transaction, per user* how much friction is actually warranted. Same fraud caught. A fraction of the friction.

### Positioning — how to neutralise the obvious objection

A judge from Paytm's risk team will think: *we already have fraud scores.* Do not fight that. **Do not claim to build a better fraud model than Paytm.**

Your contribution is the **decision layer above the score** — the part nobody has built:
- Paytm has a risk score. Nobody has the policy engine that converts a score into the *right graduated intervention* while protecting speed.
- Nobody has built RBI's proposed **trusted-person approval rail**.
- Nobody has built the **friction budget** — an explicit, measurable tradeoff between fraud prevented and legitimate payments slowed.
- Nobody has a **consent and authorization substrate** that works for both a coerced human and an autonomous AI agent.

Say this out loud in the pitch. Judges respect a builder who knows exactly where their contribution sits.

### The unifying insight (this is the intellectual core of the submission)

> Whether the principal is a **human being coerced by a scammer** or an **autonomous AI agent spending on your behalf**, the safety question is identical: *who is authorised to move my money, how much, to whom, under what conditions, with what audit trail, and how do I revoke it instantly?*

The RBI's fraud safeguards and NPCI's Unified Agent Protocol are converging on **the same set of primitives**. Kavach builds that substrate once and serves both. Phase 1 protects humans; Phase 2 governs agents. Same engine.

That framing is what elevates this from "a fraud demo" to a platform thesis — and it is exactly the conviction-then-frontier sequence you asked for.

---

## Part 5 — What you actually build

### Phase 1 — The adaptive friction engine (days 1–7)

**1. Per-user behavioural baseline.** The heart of the personalization claim. For each user, model their *own* distribution: typical amounts, payee set and its churn rate, time-of-day pattern, new-payee frequency, device stability. A ₹15,000 transfer is p99 for one user and p40 for another — **the blanket rule cannot tell them apart and that is its central flaw.**

**2. Risk scorer.** Features grouped in four families:
- *Payee* — novelty, age in ecosystem, time since added, negative-registry match (DPIP/MuleHunter-style proxy), inbound concentration.
- *Deviation from personal baseline* — amount z-score against the user's own history, off-pattern hour, unusual category.
- *Structuring / velocity* — rolling-window sum to one payee vs. single-transaction amount. **This is the one that catches what RBI's threshold misses**: six transfers of ₹9,999 in twenty minutes.
- *Coercion signals* — screen-share or remote-access app active, call in progress during payment, payee added minutes ago, urgency language in the transaction note, new device. This cluster is the digital-arrest signature.

**3. Graduated intervention ladder — the policy engine.** Score plus context maps to the *minimum sufficient* intervention:

| Level | Action | Intended for |
|---|---|---|
| 0 | Frictionless, instant | Whitelisted / known payee / in-baseline — the large majority |
| 1 | Contextual nudge naming the specific scam pattern, in the user's language | Mild anomaly |
| 2 | Cooling-off with a live cancel window (RBI's lagged credit, but targeted) | Genuine anomaly |
| 3 | Trusted-person co-approval | Vulnerable cohort / high risk — RBI's own proposal, unbuilt |
| 4 | Hard hold + kill-switch offer + guided reporting | Near-certain coercion |

**4. The friction-budget evaluation harness.** *This is the differentiating technical artifact and the reason to do this idea with your skillset.*

Measure, on a labelled cohort, the real tradeoff: **fraud value prevented vs. percentage of legitimate transactions subjected to friction.** Plot the curve. Plot RBI's blanket rule as a single point on the same axes. Then say the quantified thing:

> *The blanket rule adds friction to N% of legitimate high-value payments and misses structured fraud entirely. Kavach catches X% of fraud value at Y% friction.*

A defensible, measured, quantified comparison against the actual regulatory proposal is a far stronger artifact than any model accuracy number. Report it honestly, including where you lose.

**Checkpoint: at end of day 7 this must be demo-complete and submittable on its own.**

### Phase 2 — The agent authorization layer (days 8–12)

Generalise the same consent substrate to AI agents, explicitly anticipating UAP.

**5. Mandate engine.** Agent identity distinct from user credential; scoped authority — per-counterparty caps, per-cycle caps, beneficiary allowlist, category and time-window limits, and **pre-conditions** (e.g. *"pay this subscription only if it debits within 10% of its usual amount"*).

**6. Hash-chained audit trail + instant revocation.** Every decision — human or agent — recorded in one append-only, verifiable log. Revocation halts in-flight execution. The kill switch from Phase 1 and agent revocation are *the same mechanism*, which is the point.

**7. A worked agent scenario.** Wire one real agentic flow through Paytm's MCP Server / Agent Skills sandbox — an agent paying recurring bills under mandate, with Kavach as the gate. Show it succeed within policy, then get blocked when it exceeds scope. **The block is the demo, not the success.**

---

## Part 6 — Architecture & stack

```
sim/          synthetic cohort + labelled scam typologies      ← build with care
baseline/     per-user behavioural profiles
scoring/      risk features + scorer
policy/       intervention ladder, mandates, pre-conditions    ← the contribution
audit/        hash-chained log, revocation, kill switch
agent/        tool-calling loop over Paytm MCP, gated by policy  ← Phase 2
eval/         friction-budget harness + RBI-baseline comparison ← the differentiator
api/          FastAPI
web/          thin dashboard — do NOT over-invest here
```

**Stack:** Python + FastAPI + Postgres. Use Paytm's **MCP Server** and **Agent Skills** for the payment tooling rather than hand-rolling clients — using the host's own agentic infrastructure is a visible signal. Keep the model interpretable (gradient boosting over engineered features, not a black box): you must be able to explain *why* a transaction got Level 3 on stage, and "explainable friction" is itself part of the product.

**On data — be straight about this.** You have no real fraud data, and you will not get any. Build a **synthetic cohort generator** grounded in documented, citable scam typologies: digital arrest, KYC-expiry vishing, refund/reversal scam, task-and-investment scam, QR collect-request inversion, mule-chain layering. Include realistic legitimate hard cases too — genuine medical emergencies, a real first rent payment to a new landlord — because those are what a good engine must *not* slow down.

State plainly in the README and the pitch that the cohort is synthetic and typology-grounded. A rigorous synthetic harness with honest labels is respectable engineering. A demo implying you had real fraud data is a credibility death sentence when a Paytm risk engineer asks one follow-up question.

**Deliberately out of scope:** mobile app, real telephony/call detection, voice deepfake detection, training anything from scratch, any claim to beat Paytm's internal fraud models.

---

## Part 7 — Build sequence

**Days 1–2 — Simulator and cohort.** Users with distinct personas (young power user, salaried, senior citizen with 4 fixed payees, small merchant), transaction histories, and labelled scam injections. *The quality of this dataset determines the quality of everything downstream — do not rush it.*

**Day 3 — Baseline profiler.** Per-user distributions and payee graphs.

**Day 4 — Risk scorer.** All four feature families. Make sure the structuring detector genuinely works — it's a headline claim.

**Day 5 — Policy engine.** Intervention ladder, trusted-person approval flow, kill switch.

**Day 6 — Evaluation harness.** The friction-vs-fraud curve and the RBI-baseline comparison point. **This is the day that wins the hackathon; protect it.**

**Day 7 — Dashboard + demo cut. Phase 1 complete and submittable.** Do not begin Phase 2 until this is true.

**Days 8–9 — Mandate engine + hash-chained audit + revocation.**

**Days 10–11 — Agent loop over Paytm MCP sandbox, gated by policy.**

**Day 12 — Pitch, video, README, dry runs.**

---

## Part 8 — Demo script (3 minutes)

1. **The tension (25s).** "RBI wants a one-hour delay on every UPI transfer over ₹10,000. Industry says it breaks the thing that makes UPI work. Both are right — because the rule can't tell users apart."
2. **Speed (30s).** Priya pays her regular landlord ₹18,000. Over the threshold; the blanket rule delays it an hour. Kavach: **instant.** Show why — known payee, in-baseline, no coercion signals.
3. **Trust (45s).** Ramesh, 68. Screen-share is active, payee added 90 seconds ago, six transfers of ₹9,999 in twenty minutes. **Every single one is under RBI's threshold — the blanket rule sees nothing.** Kavach flags structuring plus the coercion cluster, holds at Level 3, routes to his daughter for approval. She declines. Show the audit entry.
4. **Personalization (25s).** The friction-budget curve. Kavach's operating point next to RBI's blanket rule. Say the number out loud.
5. **The frontier (40s).** "The same question — who may move my money, how much, to whom, under what conditions — is what NPCI's Unified Agent Protocol has to answer for AI agents." Set a mandate. Agent pays a bill within scope. Agent tries to exceed scope, gets blocked. Revoke; it halts mid-flight.
6. **Close (15s).** One trust layer. Protects humans today, governs agents tomorrow.

---

## Part 9 — Verdict on your four existing solutions

- **Solution A (Soundbox voice ERP)** — **drop.** Paytm shipped the AI Soundbox at Global Fintech Fest 2025: 11 languages, dual display, conversational business insights. You'd be rebuilding the host's product in front of the host. It's also Theme 2.
- **Solution B (Cash-flow orchestrator)** — **out of scope** for Theme 1. It was your strongest SMB idea; park it.
- **Solution C (DPDP consent SDK)** — **absorb, don't build separately.** Kavach's consent and audit substrate is the interesting half of it, with an actual demo attached.
- **Solution D (Federated GNN + IDPIC)** — **drop as a standalone.** IDPIC APIs aren't publicly available and you can't out-model Paytm's risk team in two weeks. Keep only the *idea* of a negative-registry lookup as one feature among many in the scorer.

Before pitching, scrub every borrowed statistic. The 547-store survey, the 99.5% deepfake accuracy, and the ₹48,021 Cr framing all need a source you can name aloud or they need to go.

---

## Part 10 — Verification

**Risk scorer:**
- Held-out cohort: precision/recall per intervention level. Report the confusion matrix, including false positives on the hard legitimate cases.
- Targeted test: the structuring scenario must be caught while every individual transaction sits under ₹10,000.

**Policy engine:**
- Property test — no transaction ever receives more friction than its score band permits (the "minimum sufficient friction" invariant).
- Whitelisted payee never exceeds Level 0. Vulnerable-cohort high-risk always reaches Level 3.
- Trusted-person decline blocks; approve releases; timeout defaults to blocked.

**Audit & revocation:**
- Tampering any entry fails chain verification.
- Kill switch and agent revocation both halt in-flight execution.

**Agent layer (Phase 2):**
- Adversarial: over-cap refused, non-allowlisted beneficiary refused, unmet pre-condition holds, revocation halts mid-cycle.
- End-to-end run against Paytm sandbox, twice, clean.

**Evaluation harness:**
- Reproducible from a fixed seed — a judge should be able to re-run your headline number.
- Publish the RBI-baseline comparison methodology in the README so the claim is auditable.

**Pitch:** dry-run on a timer, twice.

---

## Sources

- [RBI discussion paper, 9 Apr 2026 — safeguards in digital payments](https://www.business-standard.com/finance/personal-finance/one-hour-delay-to-upi-friction-rbi-proposals-to-fight-online-fraud-126041000580_1.html) · [proposal detail: lagged credit, trusted person, kill switch](https://www.caclubindia.com/articles/how-rbi-plans-to-stop-digital-fraud-in-india-with-new-rule-2026--55081.asp) · [RBI weighs adding frictions](https://www.business-standard.com/finance/news/rbi-digital-payments-fraud-upi-security-frictions-126052900821_1.html)
- [Industry pushback — bankers warn of ecosystem disruption](https://www.storyboard18.com/digital/rbi-proposal-on-upi-payment-delay-for-new-payees-may-disrupt-digital-ecosystem-say-bankers-95041.htm)
- [NPCI Unified Agent Protocol](https://www.business-standard.com/finance/news/india-may-allow-agentic-ai-led-upi-transactions-under-new-npci-protocol-126070801343_1.html) · [how it may work](https://www.business-standard.com/finance/news/unified-agent-protocol-will-ai-be-making-upi-payments-for-you-now-here-s-how-it-may-work-126070900865_1.html)
- [UPI Circle delegation to IoT & software — NPCI OC 201-B](https://www.lexology.com/library/detail.aspx?g=c1688ffb-5690-4b85-a174-2ff895de0d9c)
- [Paytm for Developers — MCP Server, Agent Skills, AI Router](https://www.paytmpayments.com/docs)
- [Paytm AI Soundbox launch](https://paytm.com/blog/artificial-intelligence/paytm-launches-indias-first-ai-soundbox-for-payments/)
- [DPIP / IDPIC and MuleHunter.AI adoption](https://www.business-standard.com/industry/banking/15-more-banks-to-adopt-rbi-s-mulehunter-fraud-detection-tool-by-october-125080101845_1.html)
- [UPI AutoPay mandate scale](https://www.business-standard.com/finance/personal-finance/hidden-upi-mandates-here-s-why-a-1-trial-can-cost-far-more-over-time-126070600578_1.html) · [revocations on low balance](https://www.business-standard.com/amp/finance/news/upi-autopay-revocations-hit-20-mn-monthly-over-low-customer-balances-125090700500_1.html)
- [RBI FREE-AI framework report](https://rbidocs.rbi.org.in/rdocs/PublicationReport/Pdfs/FREEAIR130820250A24FF2D4578453F824C72ED9F5D5851.PDF)
- [Paytm Build for India AI Hackathon](https://www.competehub.dev/en/competitions/hackculture_hackathons_paytm_ai_hackathon)
