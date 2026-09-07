# O'Reilly Profiles — Planned

O'Reilly requires more than one profile because its interactive sandboxes and cloud labs serve different purposes.

Potential profiles:

- Preconfigured Python/Linux/Docker/Kubernetes interactive environment.
- Short guided Azure cloud lab with temporary credentials and an assigned resource group.
- Any future general-purpose cloud sandbox that is documented separately.

The current public author documentation describes a temporary Azure user scoped to an isolated resource group and active for approximately 60 minutes. That is materially different from a four-hour open cloud sandbox, so O'Reilly-compatible exercises should usually be quick or pre-staged.

Before adding a JSON profile:

1. Confirm which experiences are available to the intended subscription type.
2. Confirm duration, resource-group behavior, allowed services, regions, and terminal capabilities.
3. Separate guided cloud-lab assumptions from general interactive sandbox behavior.
4. Do not reproduce paid lab instructions.

Starting references:

- [O'Reilly interactive learning](https://www.oreilly.com/online-learning/intro-interactive-learning/)
- [O'Reilly feature availability](https://www.oreilly.com/online-learning/support/features.html)
- [O'Reilly Azure environment author documentation](https://interactive-docs.oreilly.com/cloud-labs/authoring-azure.html)
