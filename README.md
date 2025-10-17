# Reactive Composite Memory (RCM)

> **A pattern for governed, versioned context in intelligent systems**

[![License: CC BY 4.0](https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/)
[![Spec Version](https://img.shields.io/badge/version-1.0-blue.svg)](https://github.com/critical-insight/rcm-spec/releases/tag/v1.0)
[![Status](https://img.shields.io/badge/status-Community%20Draft-orange.svg)](https://github.com/critical-insight/rcm-spec/blob/main/STATUS.md)

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
  "window": {"start": "2025-01-15T10:23:00Z", "end": "2025-01-15T10:28:00Z"},
  "watermarkAt": "2025-01-15T10:28:01Z",
  "inputs": [
    {"sourceId": "tickets", "from": "offset_42", "to": "offset_45", "hash": "abc123..."},
    {"sourceId": "kb_articles", "from": "v2024.1.1", "to": "v2024.1.1", "hash": "def456..."}
  ],
  "planHash": "sha256:xyz789...",
  "idempotencyKey": "sha256:stable_dedupe_key...",
  "ttl": "PT5M",
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
├── specification/
│   ├── rcm-spec-v1.0.md              # Full specification (164 pages)
│   ├── executive-summary.md           # 2-page overview
│   └── changelog.md                   # Version history
├── conformance/
│   ├── test-vectors/                  # Golden replay tests
│   ├── telemetry-schema.json          # Required events/metrics
│   └── report-template.json           # Conformance report format
├── examples/
│   ├── support-agent-context/         # Example from README
│   ├── fraud-detection/               # Real-time risk assessment
│   └── personalization/               # User preference management
├── guides/
│   ├── getting-started.md             # 30-minute introduction
│   ├── comparison-guide.md            # RCM vs. Event Sourcing, CQRS, caching
│   └── adoption-path.md               # Pilot → production playbook
└── LICENSE                            # CC-BY-4.0 (spec), Apache-2.0 (code)
```

---

## Getting Started

### For Evaluators

**Read these first** (15 minutes):
1. [Executive Summary](specification/executive-summary.md)
2. [Comparison Guide](guides/comparison-guide.md) - RCM vs. adjacent patterns
3. [Getting Started](guides/getting-started.md) - conceptual walkthrough

**Then**: Chapters 1-3 of the [full specification](specification/rcm-spec-v1.0.md)

### For Implementers

**Required reading**:
- Chapter 4: Normative Semantics (frame envelope, time semantics, delivery contracts)
- Annex A: Conformance and Testing (test vectors, telemetry requirements)

**Reference implementation** (coming Q1 2025): [CognOS](https://github.com/critical-insight/cognos)

### For Standards Bodies

All chapters + Annexes A-C provide formal apparatus for evaluation.

---

## Status: Community Specification

**Version**: 1.0 (January 2025)  
**Maturity**: Community Draft  
**Conformance**: Test suite defined; reference implementations in progress

### Current State

✅ Specification published (normative + informative)  
✅ Conformance test vectors defined (Annex A.5)  
✅ Telemetry schema documented (Annex A.2)  
🚧 Reference implementation underway (CognOS)  
🚧 Conformance test harness in development  
📅 Target: 3+ independent implementations by Q2 2025

### Known Implementations

| Implementation | Status | Platform | Conformance Report |
|----------------|--------|----------|-------------------|
| CognOS | In development | Multi-platform | Expected Q1 2025 |
| Kafka/Flink Reference | Planned | JVM | Q2 2025 |
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

**Key insight**: RCM doesn't replace these patterns—it **complements** them by standardizing context lifecycle.

See [Comparison Guide](guides/comparison-guide.md) for detailed decision heuristics.

---

## Contributing

We welcome contributions! This is an open, community-driven specification.

### Ways to Participate

🎯 **Submit feedback**: [Open an issue](https://github.com/critical-insight/rcm-spec/issues) for clarifications, gaps, or suggestions

📝 **Propose changes**: Fork → edit → pull request (spec text, examples, test vectors)

🔨 **Build an implementation**: Claim conformance; publish report; share learnings

🧪 **Contribute test vectors**: Add edge cases to `conformance/test-vectors/`

💬 **Join discussions**: [GitHub Discussions](https://github.com/critical-insight/rcm-spec/discussions)

📢 **Spread the word**: Blog posts, talks, case studies

### Governance

**Maintainer**: Dan Vanderboom ([@danvanderboom](https://github.com/danvanderboom))  
**Process**: Rough consensus; versioned releases; community review  
**Decisions**: Major changes require discussion issue + 2 weeks for feedback

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

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

See [examples/](examples/) for detailed scenarios.

---

## Roadmap

### Q1 2025
- ✅ Publish v1.0 specification
- 🚧 Release CognOS reference implementation
- 🚧 Launch conformance test harness
- 📅 Host community kickoff call

### Q2 2025
- 📅 3+ independent implementations
- 📅 Public conformance reports
- 📅 Crosswalks to LangChain, Semantic Kernel, LlamaIndex
- 📅 Submit paper to SIGMOD/VLDB

### H2 2025
- 📅 Standards body engagement (OASIS/CNCF)
- 📅 Cloud provider integrations (AWS, Azure, GCP)
- 📅 MCP/A2A protocol alignment
- 📅 V1.1 based on implementation feedback

See [ROADMAP.md](ROADMAP.md) for details.

---

## License

- **Specification text**: [Creative Commons Attribution 4.0 (CC-BY-4.0)](https://creativecommons.org/licenses/by/4.0/)
- **Code examples & test suite**: [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0)

You are free to implement, extend, and distribute implementations under any license. Attribution to this spec is appreciated but not required.

---

## Contact

**Questions?** [Open a discussion](https://github.com/critical-insight/rcm-spec/discussions)  
**Found a bug?** [File an issue](https://github.com/critical-insight/rcm-spec/issues)  
**Want to chat?** Email: rcm-spec@criticalinsight.com  
**Latest updates**: Watch this repo or follow [@CriticalInsightInc](https://twitter.com/CriticalInsightInc)

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

📖 [Full Specification](specification/rcm-spec-v1.0.md)  
📄 [Executive Summary](specification/executive-summary.md)  
🚀 [Getting Started Guide](guides/getting-started.md)  
⚖️ [Comparison Guide](guides/comparison-guide.md)  
🧪 [Conformance Tests](conformance/)  
💡 [Examples](examples/)  
🗺️ [Roadmap](ROADMAP.md)  
🤝 [Contributing](CONTRIBUTING.md)  

---

<p align="center">
  <strong>Building intelligent systems that remember reliably, explain credibly, and scale economically.</strong>
</p>

<p align="center">
  <a href="https://github.com/critical-insight/rcm-spec/stargazers">⭐ Star this repo</a> if RCM solves a problem you face!
</p>