# Reactive Composite Memory (RCM)

> **A pattern for governed, versioned context in intelligent systems**

[![License: CC BY 4.0](https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/)
[![Spec Version](https://img.shields.io/badge/version-1.0-blue.svg)](https://github.com/critical-insight-ai/rcm-spec/releases)
[![Status](https://img.shields.io/badge/status-Community%20Draft-orange.svg)](#status-community-specification)

---

## What is RCM?

Modern intelligent systems—AI agents, real-time operations platforms, personalization engines—need to remember across sessions, justify outcomes, and control costs. Traditional approaches (per-request assembly, static caches, batch ETL) are brittle: they lack provenance, consistent update semantics, and reliable cost attribution.

**Reactive Composite Memory (RCM)** treats context as a **living, versioned, governed artifact** that updates reactively, carries its lineage, and can be reused by many consumers without duplication.

### The Core Flow

```
Source Changes → Views → Materializer → Frames → Subscriptions → Consumers
    ↓             ↓          ↓            ↓           ↓             ↓
 (events)    (declarative) (time)   (versioned)  (ordered)   (idempotent)
```

**What makes it reactive**: When a source changes, affected views recompute and emit new frames automatically. Consumers subscribe to frame streams rather than polling or rebuilding context.

**What makes it trustworthy**: Every frame carries complete lineage (inputs + transform hash), time bounds (watermarks), and version history—making decisions auditable by construction.

**What makes it scalable**: Recomputation happens on change (data velocity), not on traffic (request volume). One set of frames serves agents, dashboards, analytics—no parallel caches.

---

## Quick Example

**Problem**: A support agent needs fresh context about a customer—profile, recent tickets, relevant KB articles—but current systems either:
- Rebuild context on every page load (expensive, no lineage)
- Cache stale data (fast but wrong)
- Query multiple services synchronously (slow, fragile)

**RCM Solution**:

```yaml
# Define view declaratively
view:
  id: support_context
  sources:
    - user_profile (reference data)
    - tickets (CDC stream)
    - kb_articles (search index updates)
  composition:
    join: [profile, recent_tickets(last=10), relevant_articles(top=5)]
  window: session (5min gap)
  ttl: PT5M

# System automatically:
# - Materializes frames when any source changes
# - Versions each frame monotonically
# - Records lineage (which ticket versions, which KB articles)
# - Delivers to subscribed consumers (agent UI, analytics, audit log)

# Agent receives:
{
  "frameId": "01JBQR...",
  "contextId": "support_context",
  "key": "customer_12345",
  "version": 47,
  "type": "snapshot",
  "window": {"start": "2025-01-15T10:23:00Z", "end": "2025-01-15T10:28:00Z"},
  "watermarkAt": "2025-01-15T10:28:01Z",
  "inputs": [
    {"sourceId": "tickets", "from": "offset_42", "to": "offset_45", "hash": "abc123..."},
    {"sourceId": "kb_articles", "from": "v2024.1.1", "to": "v2024.1.1", "hash": "def456..."}
  ],
  "planHash": "sha256:xyz789...",
  "idempotencyKey": "sha256:stable_dedupe_key...",
  "ttl": "PT5M",
  "createdAt": "2025-01-15T10:28:01Z",
  "body": {
    "profile": {...},
    "recentTickets": [...],
    "relevantArticles": [...]
  }
}
```

**Result**: Agent always sees fresh context, "why does the agent see X?" is answerable via `inputs`, costs are predictable (recompute once per change, not per agent).

---

## Why RCM?

### Problems RCM Solves

| Problem | Traditional Approach | RCM Approach |
|---------|---------------------|--------------|
| **Freshness** | Poll or cache with TTL | Reactive: updates propagate automatically |
| **Explainability** | "¯\\\_(ツ)\_/¯" | Every frame cites sources + transform |
| **Cost** | Scales with traffic | Scales with change rate; reuse across consumers |
| **Consistency** | Cache stampedes, race conditions | Deterministic recomputation; ordered delivery |
| **Governance** | Per-pipeline band-aids | Uniform extension points (policy, budgets, security) |

### What RCM Guarantees

✅ **Reactive updates**: Contexts stay fresh without polling  
✅ **Deterministic**: Same inputs → same outputs → safe replay  
✅ **Versioned**: Monotone per key; replay by version or time interval  
✅ **Provenance**: Every frame records inputs (ranges + hashes) and plan identity  
✅ **Ordered delivery**: Per-key ordering; at-least-once guarantees  
✅ **Idempotent**: Duplicate deliveries handled safely  
✅ **Governed**: Extension points for admission control, budgets, security

---

## Repository Contents

```
rcm-spec/
├── README.md                          # You are here
├── Reactive-Composite-Memory.docx     # Full specification (source of truth)
├── Reactive-Composite-Memory.md       # Markdown export of the spec (generated; do not edit by hand)
├── generate-spec-md.bat               # Regenerates the Markdown export with pandoc
├── media/                             # Figures extracted from the .docx by the export
├── diagrams/
│   └── rcm-overview.mmd               # Mermaid source for the Chapter 3 overview figure
└── LICENSE.md                         # CC-BY-4.0 (spec), Apache-2.0 (code)
```

**Planned additions** (not yet in the repo): an executive summary, getting-started and comparison guides, a `conformance/` folder with golden test vectors, the telemetry schema and conformance report template, and worked `examples/`. Until then, the corresponding material lives in the specification itself: Chapter 5 is the comparison guide, Section 6.3 is the adoption path, and Annex A defines the test vectors and report format.

---

## Getting Started

### For Evaluators

**Read these first** (15 minutes), all in the [full specification](Reactive-Composite-Memory.md):
1. Abstract and Chapter 1 (Introduction) - purpose, scope, what RCM is and is not
2. Chapter 3 (RCM in One Picture) - visual model and illustrative flow
3. Chapter 5 (Comparative Guide) - RCM vs. adjacent patterns, with decision heuristics

**Then**: Chapter 2 (Problem and Design Forces) and Section 6.3 (Adoption Path)

### For Implementers

**Required reading**:
- Chapter 4: Normative Semantics (frame envelope, time semantics, delivery contracts)
- Annex A: Conformance and Testing (test vectors, telemetry requirements)

**Reference implementation** (in development): [CognOS](https://cognos.is), the first implementation of RCM. A gap assessment of its Dataflow module against Chapter 4 and Annex A was completed in October 2026 and is driving both the implementation and the next spec revision.

### For Standards Bodies

All chapters + Annexes A-C provide formal apparatus for evaluation.

---

## Status: Community Specification

**Version**: 1.0 (October 2025)  
**Maturity**: Community Draft  
**Conformance**: Core semantics (reactive composition, versioning, time, ordering, delivery) are testable and portable. Extension points (governance) are optional and implementation-defined.

### Current State (as of October 2026)

✅ Specification v1.0 published, October 2025 (normative + informative)  
✅ Conformance test vectors defined (Annex A.5) and telemetry schema documented (Annex A.2)  
✅ First implementation exists (CognOS) and has been assessed against the spec  
🚧 Spec revision in progress, folding in what the first implementation taught us (see the change log in Appendix III)  
🚧 CognOS closing its conformance gaps (window closure, per-key ordering, per-key version sequence, replay by version, budget settlement)  
📅 Conformance test harness: requirements defined in Annex A; no harness published yet  
📅 No independent (non-CognOS) implementation yet

### Known Implementations

| Implementation | Status | Platform | Conformance Report |
|----------------|--------|----------|-------------------|
| CognOS | In development; gap assessment completed October 2026 | .NET / Orleans | Not yet (about 4 of 9 core test vectors would pass today) |
| _Your implementation?_ | - | - | [Join us!](#contributing) |

---

## How RCM Relates to Other Patterns

| Pattern | Relationship |
|---------|--------------|
| **Event Sourcing** | RCM consumes ES logs; frames are governed read models |
| **CQRS** | RCM implements the read side with reactive semantics |
| **Materialized Views** | RCM standardizes MVs with portable envelopes and delivery contracts |
| **Caching (Redis)** | RCM isn't a cache—frames carry versioning, lineage, and governance |
| **Reactive Streams** | Flow control is complementary; RCM adds memory lifecycle |
| **Redux/Elm/MVU** | Same unidirectional flow; RCM extends to durable, multi-consumer memory |
| **MCP** | RCM provides internal substrate; MCP exposes at edges |
| **Knowledge Graphs** | RCM delivers fresh graph slices reactively with provenance |
| **Major Cloud Platforms** | RCM provides abstraction layer above vendor primitives (Databricks, Snowflake, AWS, Azure) |

**Key insight**: RCM doesn't replace these patterns—it **complements** them by standardizing context lifecycle.

See Chapter 5 of the [specification](Reactive-Composite-Memory.md) for detailed decision heuristics.

---

## Contributing

We welcome contributions! This is an open, community-driven specification.

### Ways to Participate

🎯 **Submit feedback**: [Open an issue](https://github.com/critical-insight-ai/rcm-spec/issues) for clarifications, gaps, or suggestions

📝 **Propose changes**: Fork → edit → pull request (spec text, examples, test vectors)

🔨 **Build an implementation**: Claim conformance; publish report; share learnings

🧪 **Contribute test vectors**: Propose edge cases in the format defined in Annex A.8.3 (a `conformance/test-vectors/` folder will be added to hold them)

💬 **Join discussions**: Use [GitHub Issues](https://github.com/critical-insight-ai/rcm-spec/issues) for now; GitHub Discussions will be enabled as the community grows

📢 **Spread the word**: Blog posts, talks, case studies

### Governance

**Maintainer**: Dan Vanderboom ([@danvanderboom](https://github.com/danvanderboom))  
**Process**: Rough consensus; versioned releases; community review  
**Decisions**: Major changes require discussion issue + 2 weeks for feedback

Detailed contribution guidelines (CONTRIBUTING.md) are planned; until then, open an issue to discuss a change before submitting a pull request.

---

## Use Cases

### AI Agents & LLM Applications
- **Problem**: Per-inference context assembly is expensive; no audit trail
- **RCM Solution**: Fresh, governed frames with lineage; reuse across inference calls
- **Impact**: 10× cost reduction; full explainability

### Real-Time Operations
- **Problem**: Dashboards poll or show stale data; no consistent truth
- **RCM Solution**: Subscribe to frames; automatic updates; shared substrate
- **Impact**: Sub-second freshness; reduced backend load

### Compliance & Audit
- **Problem**: "What did we know when?" requires log archaeology
- **RCM Solution**: Versioned frames with time bounds and provenance
- **Impact**: Instant replay by version or interval; regulator-ready

### Multi-Tenant SaaS
- **Problem**: Cost attribution unclear; no capacity control
- **RCM Solution**: Per-tenant budgets; governed admission; telemetry
- **Impact**: Predictable costs; fair resource allocation

Worked example scenarios are planned for an `examples/` folder; Section 5.3 of the specification walks through co-existence patterns in the meantime.

---

## Roadmap

Status as of October 2026. Dates are given only for what has happened; the rest is ordered by dependency, not scheduled.

### Done
- ✅ v1.0 specification published (October 2025)
- ✅ First implementation (CognOS) built against v1.0
- ✅ Gap assessment of CognOS against Chapter 4 and Annex A (October 2026)

### In progress
- 🚧 Spec revision from implementation feedback: admission telemetry (`hook` and `stage`), window lifecycle and grace, sliding-window overlap, per-partition watermarks, metric label hygiene, telemetry catalogue consistency
- 🚧 CognOS conformance work: watermark-gated window closure, per-key `(window.end, version)` delivery order, per-key version sequence, corrective deltas, budget lease settlement, replay by version

### Next, in order
1. Decide the redaction model (plan operator vs. egress projection) and fix §4.7 and test EX-3 accordingly
2. Publish the revised spec (v1.1 or v1.0.1, depending on whether the telemetry label changes are treated as breaking)
3. Executive summary and getting-started guide; worked examples
4. Conformance test harness and golden vectors (Annex A.5, A.8.3); first CognOS conformance report
5. Architecture diagrams (Mermaid sources in `diagrams/`)

### Later
- Independent implementations (target: 3+) and public conformance reports
- Crosswalks to LangChain, Semantic Kernel, LlamaIndex
- MCP/A2A protocol alignment; cloud provider integration notes (AWS, Azure, GCP)
- Standards body engagement (OASIS/CNCF); paper submission (SIGMOD/VLDB)

---

## License

- **Specification text**: [Creative Commons Attribution 4.0 (CC-BY-4.0)](https://creativecommons.org/licenses/by/4.0/)
- **Code examples & test suite**: [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0)

You are free to implement, extend, and distribute implementations under any license. Attribution to this spec is appreciated but not required.

---

## Contact

**Questions or bugs?** [Open an issue](https://github.com/critical-insight-ai/rcm-spec/issues)  
**Want to chat?** Email: dan@criticalinsight.ai  
**Latest updates**: Watch this repo

---

## Acknowledgments

This specification draws on decades of distributed systems research:

- **Stream processing**: Tyler Akidau & the Dataflow Model team (watermarks, event-time)
- **Reactive architectures**: Reactive Streams, Elm, Redux communities
- **Event-driven patterns**: Martin Fowler, Greg Young (Event Sourcing, CQRS)
- **Cognitive science**: William James, Atkinson-Shiffrin, Baddeley, Tulving
- **Interoperability**: Anthropic (MCP), agent communication standards (FIPA-ACL)

Thank you to early reviewers and the open-source community for ongoing collaboration.

---

## Quick Links

📖 [Full Specification (Markdown)](Reactive-Composite-Memory.md)  
📝 [Full Specification (Word source)](Reactive-Composite-Memory.docx)  
🖼️ [Diagram sources](diagrams/)  
⚖️ [License](LICENSE.md)  
🗺️ [Roadmap](#roadmap)  
🤝 [Contributing](#contributing)  

Planned, not yet available: executive summary, getting-started guide, standalone comparison guide, conformance test kit, worked examples.

---

<p align="center">
  <strong>Building intelligent systems that remember reliably, explain credibly, and scale economically.</strong>
</p>

<p align="center">
  <a href="https://github.com/critical-insight-ai/rcm-spec/stargazers">⭐ Star this repo</a> if RCM solves a problem you face!
</p>