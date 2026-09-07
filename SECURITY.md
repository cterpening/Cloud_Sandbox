# Security Policy

## Educational scope

This project contains educational examples, not a supported production platform. Sandbox-compatible configurations may intentionally omit features unavailable in a learning environment. Those compromises must be labeled and must not be presented as production recommendations.

## Sensitive material

Do not commit:

- Cloud credentials, tokens, certificates, or private keys.
- Terraform state or plan files containing sensitive values.
- Tenant, subscription, project, or account identifiers from real environments.
- Customer data or internal company information.
- Logs and evidence that have not been sanitized.

Sample values must be unmistakably synthetic.

## Safe infrastructure behavior

- Deployment and cleanup scripts must display their target cloud, subscription/account/project, region, and resource scope.
- Destructive operations must require an explicit confirmation.
- Published automation must avoid broad subscription/account/project-level deletion.
- Prefer a dedicated lab resource group, stack, or project boundary.
- Do not make public endpoints the default when a sandbox supports a safe alternative.
- If a sandbox prevents the safe alternative, label the exposure and minimize its lifetime and scope.

## Reporting a problem

Do not open a public issue containing an active secret or real environment identifier. Revoke the credential first, sanitize evidence, and use the repository owner's private security-reporting channel when one is configured.
