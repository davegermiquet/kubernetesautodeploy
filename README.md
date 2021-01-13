J|Components Installed | Description |
| ----------- | ----------- |
| Docker   |  Container/Linux System |
| Kubernetes  |  Cluster/Management System (manages docker)|
| Felix | Main task: Programs routes and ACLs, and anything else required on the host to provide desired connectivity for the endpoints on that host. Runs on each machine that hosts endpoints. Runs as an agent daemon|
| (Calico CNI PLugin) | The Calico binary that presents this API to Kubernetes is called the CNI plugin, and must be installed on every node in the Kubernetes cluster. The Calico CNI plugin allows you to use Calico networking for any orchestrator that makes use of the CNI networking specification. Configured through the standard CNI configuration mechanism, and Calico CNI plugin.|
| IPAM plugin | Main task: Uses Calico’s IP pool resource to control how IP addresses are allocated to pods within the cluster. It is the default plugin used by most Calico installations. It is one of the Calico CNI plugins.|
| kube-controllers | Main task: Monitors the Kubernetes API and performs actions based on cluster state. kube-controllers.|
| Typha | Main task: Increases scale by reducing each node’s impact on the datastore. Runs as a daemon between the datastore and instances of Felix. Installed by default, but not configured. Typha description, and Typha component.|
| calicoctl | Main task: Command line interface to create, read, update, and delete Calico objects. calicoctl command line is available on any host with network access to the Calico datastore as either a binary or a container. Requires separate installation. calicoctl. |

Severs Deployed:

- 2 EC2 Instances
- Squid
- Kubernetes Master
- Kubernetes Node
- VPC Network With only specific ports open for kubernetes
- A Private and Public Network
- Node On Private Network no access to outside world except through squid
- Master on public network
