# Architecture Sandbox Compatibility Mapper

## Purpose

Map authoritative cloud reference architectures to sandbox capabilities so a learner can answer:

- Can this architecture run as documented?
- If not, which components are blocked?
- Can a smaller version preserve the learning objective?
- What should remain design-only?
- Which lab exercises the relevant components?

## Classification

| Classification | Definition |
| --- | --- |
| Compatible | The architecture's required services and permissions fit the profile. |
| Adaptable | The full design does not fit, but a smaller implementation preserves useful behavior. |
| Design only | The pattern is educational, but essential execution requirements are unavailable. |
| Unsuitable | Attempting the architecture would be misleading, unsafe, or unable to demonstrate its main objective. |
| Unknown | Documentation is insufficient; a safe validation is required. |

## Mapping workflow

1. Inventory a reference architecture by title, canonical URL, category, and cloud.
2. Summarize its intent in original language.
3. Record its required capabilities and named services.
4. Separate essential components from optional production controls.
5. Compare the selected cloud implementation with the sandbox profile.
6. Propose substitutions without claiming architectural equivalence.
7. Link to a deployable lab or add a backlog item.
8. Record the review date and sources.

## Sample Azure classifications

These are hypotheses for backlog planning, not verified lab results.

| Pattern | Initial classification | Likely adaptation |
| --- | --- | --- |
| Serverless web API | Compatible | Use consumption tiers and synthetic traffic. |
| Event-driven processing | Compatible | Keep Event Hubs and messaging inside documented limits. |
| Observable web application | Compatible | Use App Service or Container Apps with Azure Monitor. |
| AKS microservices | Adaptable | Use one small cluster and no GPU dependency. |
| Enterprise RAG | Adaptable | Use one small AI Search index and mock or separate AI inference. |
| GPU-based LLM serving | Design only | Simulate an OpenAI-compatible server; document the GPU extension. |
| Enterprise landing zone | Unsuitable for deployment | Study and validate policies at reduced scope; management groups and identity administration are unavailable. |
| Hybrid ExpressRoute topology | Design only | Model routing and DNS locally; ExpressRoute is unavailable. |

## Copyright and attribution

The mapper stores titles, links, service metadata, original summaries, and project-authored classifications. It does not copy proprietary diagrams or substantial source text. Official reference pages remain authoritative.

## Future automation

- Inventory Azure Architecture Center entries.
- Detect changed or removed source pages.
- Compare architecture requirements against platform profiles.
- Generate a compatibility table and GitHub Pages filters.
- Open an issue when a source or classification requires human review.
- Preserve prior classifications to show how sandbox capabilities change over time.
