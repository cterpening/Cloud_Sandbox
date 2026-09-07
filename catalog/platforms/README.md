# Sandbox Platform Profiles

A profile records the documented behavior of one sandbox-platform and cloud-provider combination.

Examples:

```text
pluralsight/azure.json
pluralsight/aws.json
pluralsight/gcp.json
whizlabs/azure.json       # future
oreilly/azure.json        # future
```

Profiles do not contain credentials or identifiers from a real session.

## Profile coverage

- `initial_priority_services`: enough detail to plan and validate the current backlog; not a complete transcription of the vendor table.
- `future_seed`: a small set of current facts proving the schema can represent another cloud; not ready for lab verification.
- `complete`: all relevant published limits have been reviewed and runtime-sensitive caveats are documented.

## Status values

| Status | Meaning |
| --- | --- |
| `supported` | Listed as available without a specific project-level limit. |
| `conditional` | Available only under named SKUs, quotas, regions, or restrictions. |
| `separate_environment` | Available only in a different sandbox type or pre-created environment. |
| `unsupported` | Currently unavailable in the selected profile. |
| `unknown` | Reliable information has not been recorded. |

Vendor documentation remains authoritative. Profiles capture an interpretation for compatibility planning and require a real run before a lab is marked verified.
