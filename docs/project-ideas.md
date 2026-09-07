# What else could we premake?

This is an idea menu, not a curriculum or a support promise. Ten projects are
implemented; the [shelf](../labs/README.md) is the current executable catalog. This
menu also preserves **proposals** needing their own profile check and deployment. A few useful combinations are a starting point, not a claim
that all possible combinations work.

## Next experiments

| Area | Premade idea | Interesting thing to try |
| --- | --- | --- |
| Applications | Blob upload inbox | Follow a synthetic file's processing state. |
| Events | Event Grid event trail | Retry an event and identify duplicate handling. |
| APIs | Pagination and throttling | Compare bounded and unbounded retry behavior. |
| Jobs | Scheduled cleanup preview | List expired sample records; approve deletion. |
| Messaging | Competing consumers | Change worker count and observe ordering. |
| Messaging | Dead-letter repair station | Validate and re-enqueue corrected messages. |
| Data | SQL versus table modeling | Answer one question with two small data models. |
| Data | Cosmos partition choices | Observe an uneven synthetic workload. |
| Data | Cache-aside toy shop | Compare stale data, expiry and invalidation. |
| Networking | Two-subnet connectivity | Predict which test connections an NSG allows. |
| Networking | Private DNS detective | Separate resolution from service reachability. |
| Networking | Gateway routing | Introduce one bad route across two tiny backends. |
| Containers | Revision playground | Compare versions and rehearse rollback. |
| Containers | Guestbook modernization | Replace stale images/manifests with a maintained toy app. |
| Observability | Trace-to-incident notebook | Link a failed request, dependency and hypothesis. |
| Observability | Alert noise lab | Compare noisy and deliberately tuned thresholds. |
| Configuration | Terraform drift | Detect and reconcile one approved setting change. |
| Configuration | Sandbox policy tests | Block unsafe SKUs and over-limit counts early. |
| Retrieval | Retrieval comparison | Compare token matching and search rankings. |
| AI-adjacent | Inference simulator | Practice timeouts and evaluation with deterministic replies. |
| AI-adjacent | Incident assistant | Propose—but never auto-run—a repair from synthetic evidence. |
| Composition | Tiny order system | Combine API, queue, receipt, failure and evidence. |

The new file pipeline, Network Detective, Container Playground, SQL Inventory and
Feature Flags projects cover selected ideas above. Container revisions/traffic
splitting, Cosmos, cache-aside and a composed order system remain proposals. A composed project should
share infrastructure; do not deploy every root together to create a capstone.

## How the screenshot's links influence the ideas

These links are inspiration, not code copied into this repository:

- [System Design Academy](https://github.com/systemdesign42/system-design-academy):
  translate selected pattern questions into original runnable experiments.
- [AI System Design Guide](https://github.com/ombharatiya/ai-system-design-guide):
  start with retrieval and evidence evaluation where no model access is needed.
- [Kubernetes Go guestbook](https://github.com/kubernetes/examples/tree/master/web/guestbook-go):
  an application idea worth modernizing, not a ready-made sandbox deployment.
- [Kubernetes vLLM example](https://github.com/kubernetes/examples/tree/master/AI/vllm-deployment):
  GPU-dependent; keep actual GPU inference outside this normal Azure profile.
  A deterministic simulator is a different, explicitly labeled future experiment.
- [DevOps AI Playbook](https://github.com/vishakhasadhwani/devops-ai-playbook):
  operational workflow inspiration; AWS-oriented infrastructure is not an Azure drop-in.

Links inspected 2026-09-06. Check licenses before reusing third-party code.
These experiments use original synthetic workloads, not paid course content.
See [primary capability sources](sources.md) for actual platform constraints.

## Adding one

Describe the small thing someone can try, choose its services, declare quotas and
compromises, and add a repeatable check. Mark it implemented after offline checks;
mark it verified only after a documented live session. Keep each project useful
on its own before adding a larger capstone.
