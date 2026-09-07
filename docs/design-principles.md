# Design Principles

## 1. Constraints are architecture inputs

Time limits, permissions, quotas, regions, identity restrictions, and cleanup behavior belong in the design—not in a troubleshooting footnote.

## 2. Portable concept, honest implementation

Learning objectives should transfer across clouds. Implementations should preserve meaningful provider differences rather than hiding them behind a lowest-common-denominator abstraction.

## 3. Sandbox-safe and production-aware

Every material sandbox compromise must include:

- Why the compromise exists.
- What risk it creates.
- How its lifetime and scope are minimized.
- What the production design should do instead.

## 4. Fast failure before provisioning

Validate duration, services, permissions, region, SKUs, and quotas as early as possible. A learner should not spend most of a four-hour session discovering that the final service is forbidden.

## 5. Reproducible and disposable

Labs begin from an empty or assigned environment, use deterministic configuration, generate their own synthetic data, and tolerate complete deletion afterward.

## 6. Safe by default

- Show the target scope before deployment or cleanup.
- Do not use unattended apply or destroy operations.
- Avoid broad permissions.
- Do not store credentials in files committed to Git.
- Never use real organizational or customer data.

## 7. Evidence before expiration

The learning output should outlive the sandbox. Each lab defines what to export and how to sanitize it.

## 8. Primary sources and visible freshness

Service limits and architectural facts should point to authoritative documentation. Profiles record both the source's published update date, when available, and this project's verification date.

## 9. No proprietary course reproduction

This project may state that a lab is compatible with a learning platform, but it must not copy that platform's paid instructions, assessments, screenshots, or hidden validation rules.

## 10. Time-boxed content

| Tier | Target duration | Typical use |
| --- | ---: | --- |
| Quick | 15–30 minutes | One concept or verification exercise. |
| Standard | 45–90 minutes | One deployable pattern. |
| Extended | 90–180 minutes | Multi-service scenario. |
| Maximum | 180–240 minutes | Capstone requiring a full standard Pluralsight session. |

A lab should reserve time for cleanup and evidence collection rather than using the entire session for provisioning.

## 11. Repository as the operating system

Durable instructions, manifests, scripts, decision records, and backlog state should allow a human or coding agent to resume work without reconstructing intent from chat history.

## 12. Small verified increments

Implement and verify one thin vertical slice before adding architecture breadth. A five-service lab that works is more valuable than a twenty-service diagram that has never been run.
