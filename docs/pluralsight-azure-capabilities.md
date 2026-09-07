# Pluralsight Azure Capability Summary

## Status

- Profile scope: initial priority services for backlog planning.
- Project review date: 2026-09-06.
- The authoritative Pluralsight service table remains the source of truth.
- A real sandbox run is still required before marking a lab `verified`.

## Session behavior

| Capability | Documented behavior |
| --- | --- |
| Standard Azure cloud sandbox | Four-hour session for individual learners. Some business plans can extend by four hours. |
| AI cloud sandbox | Three-hour session. |
| Concurrent sandboxes | One active sandbox in the Hands-on Playground. |
| Persistence | Access and sandbox data disappear when the session is deleted or expires. |

## Important Azure constraints

| Area | Initial interpretation for this project |
| --- | --- |
| Identity | Microsoft Entra ID administration and managed identities are unavailable in the normal sandbox. |
| Compute | Small approved VM sizes; no GPU or TPU. |
| Containers | Container Apps is supported. ACI and ACR have quotas. AKS is limited to three clusters and three nodes per cluster. |
| Application platform | Functions is supported. App Service is limited to selected F1/B/S/Y1 SKUs and two server farms. |
| AI | Azure AI Foundry is unavailable in the normal sandbox. Azure OpenAI is exposed through a separate AI sandbox with a pre-created deployment and 4,000 TPM. |
| Search | AI Search is limited to Free/Basic, one service/index/indexer/data source/skillset, 20,000 documents, and 500 MB storage/vector index. |
| Data | Cosmos DB requires provisioned throughput at or below 1,000 RU/s. Azure SQL permits Basic and selected Standard tiers. |
| Integration | Event Grid, Logic Apps, Service Bus, and Functions are useful supported building blocks. |
| Monitoring | Azure Monitor alerting, insights, and operational insights are supported; Sentinel is listed as supported. |
| Networking | VNet, NAT, Application Gateway, Front Door, Private Link, Load Balancer, and selected other services are listed as supported or conditional. ExpressRoute is unavailable. |
| Governance | Azure Policy is supported. Management Groups and Azure Resource Graph are unavailable. |
| DevOps | Azure DevOps is unavailable in the sandbox; repository CI should default to offline validation. |

## Consequences for lab design

1. Do not make managed identity a requirement for sandbox execution.
2. Clearly label any temporary connection-string or key-based workaround.
3. Preserve managed identity as the recommended production extension.
4. Avoid GPU-dependent labs; use inference simulation or design-only extensions.
5. Keep the standard lab under 90 minutes and the capstone under 180 minutes when practical.
6. Do not require the Azure cloud sandbox and AI cloud sandbox simultaneously.
7. Save synthetic evidence locally before ending the session.
8. Accept an existing resource group because some learning environments restrict resource-group creation.
9. Use low-cost, fast-provisioning SKUs and bounded scale.
10. Validate actual regional capacity and provider registration during preflight.

## Sources

- [Pluralsight Azure cloud sandbox](https://help.pluralsight.com/hc/en-us/articles/24392988447636-Azure-cloud-sandbox)
- [Pluralsight AI sandboxes](https://help.pluralsight.com/hc/en-us/articles/24564569570580-AI-sandboxes)
- [Pluralsight Hands-on Playground overview](https://help.pluralsight.com/hc/en-us/articles/24564263824404-Hands-on-Playground-overview)
- [Pluralsight cloud sandboxes getting started](https://help.pluralsight.com/hc/en-us/articles/24425549311380-Cloud-sandboxes-getting-started)

Pluralsight states that its support list can change. Future automation should detect page changes and request human review instead of silently rewriting the compatibility profile.
