# ADR 0005: A shelf of small runnable projects

- Status: Accepted
- Date: 2026-09-06

## Context

The owner wants premade things people can try and remix in limited sandboxes, not
only Terraform examples or a prescribed curriculum. The first scaffold described
many possibilities but provided no runnable workload.

## Decision

Ship five independent experiments: observable API, notes, queue/poison messages,
broken dependency and retrieval. Reuse one small Python workload and one Terraform
module, with a separate root/state per project. Every experiment runs locally
without Azure packages; cloud mode uses real Azure SDKs and resources.

Start with the normal Pluralsight Azure profile. Reuse the supplied resource group,
use one Y1 plan per experiment, and add only the queue or search service needed.
Keep connection-string compromises explicit. Require a reviewed apply and a fresh
confirmation immediately before cleanup. Do not add automated cloud deployment to CI.

Treat documentation-backed compatibility, implemented code, offline test results,
and live sandbox verification as different states. Leave verification records empty
until deployment, experiment and cleanup succeed in a real session.

## Consequences

Users can try an idea immediately and see the application as well as its infrastructure.
Shared code is easier to maintain but changes must test every project. Local behavior
does not prove Azure policy, regional availability, timing or deployment permission.
The collection covers several patterns, not a majority of Azure services yet.
Keep broader ideas on the menu and add live verification before claiming support.
