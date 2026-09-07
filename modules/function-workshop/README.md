# Function workshop foundation

Used by five independent lab roots. Creates one Linux Y1 plan, one Python 3.11
Function App, one LRS storage account with an `items` table, a Log Analytics
workspace, Application Insights and an HTTP-error metric alert. Queue/search
projects add a Basic Service Bus namespace/queue or a Free AI Search service.

The supplied resource group is a **data source**, never a managed resource.
Deploy one project at a time: five independent roots would otherwise exceed the
documented two-server-farm limit. The module restricts the Function/SCM endpoints
to the learner's IPv4 /32. Data routes also require a Function key. Storage and
search use authenticated public service endpoints; the Y1 sample does not claim
private-network integration. Shared keys are a temporary sandbox compromise;
production should use supported workload identities, access controls and network
isolation. Azure state contains keys even though they are not Terraform outputs.

Source review: 2026-09-06. Infrastructure is statically validated, not yet verified
inside a real Pluralsight session. Actual regional capacity, runtime support,
provider registration and SCM deployment permission require preflight and a run.

- [Pluralsight limits](https://help.pluralsight.com/hc/en-us/articles/24392988447636-Azure-cloud-sandbox)
- [Pinned AzureRM Function App resource](https://registry.terraform.io/providers/hashicorp/azurerm/4.64.0/docs/resources/linux_function_app)
- [Functions remote builds](https://learn.microsoft.com/en-us/azure/azure-functions/functions-deployment-technologies#remote-build)

The search index and documents are created by the authenticated sample app's
explicit seed action. Terraform owns their parent service; deleting that service
removes its index. Queue messages and table entities are similarly application data.
