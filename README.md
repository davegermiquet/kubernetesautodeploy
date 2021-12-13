|Components Installed | Description |
| ----------- | ----------- |
| Docker   |  Container/Linux System |
| Kubernetes  |  Cluster/Management System (manages docker)|
| Felix | Main task: Programs routes and ACLs, and anything else required on the host to provide desired connectivity for the endpoints on that host. Runs on each machine that hosts endpoints. Runs as an agent daemon|
| (Calico CNI PLugin) | The Calico binary that presents this API to Kubernetes is called the CNI plugin, and must be installed on every node in the Kubernetes cluster. The Calico CNI plugin allows you to use Calico networking for any orchestrator that makes use of the CNI networking specification. Configured through the standard CNI configuration mechanism, and Calico CNI plugin.|
| IPAM plugin | Main task: Uses Calico’s IP pool resource to control how IP addresses are allocated to pods within the cluster. It is the default plugin used by most Calico installations. It is one of the Calico CNI plugins.|
| kube-controllers | Main task: Monitors the Kubernetes API and performs actions based on cluster state. kube-controllers.|
| Typha | Main task: Increases scale by reducing each node’s impact on the datastore. Runs as a daemon between the datastore and instances of Felix. Installed by default, but not configured. Typha description, and Typha component.|
| calicoctl | Main task: Command line interface to create, read, update, and delete Calico objects. calicoctl command line is available on any host with network access to the Calico datastore as either a binary or a container. Requires separate installation. calicoctl. |

Server Requirements:

1 Server 
- Digital Ocean Example:

  David Germiquet / 8 GB Memory / 4 AMD vCPUs / 160 GB Disk / NYC1 - Fedora 34 x64

PreRequisites:

- Fresh Fedora 34 client Target

I used vagrant within vagrant example VagrantFile

Vagrant.configure("2") do |config|
config.vm.provider "libvirt" do |v|
     v.memory = 6000  
     v.cpus = 2
  end
  config.vm.network "public_network", :bridge => "enp2s0f0", :dev => "enp2s0f0" 
  config.vm.box = "fedora/34-cloud-base"
  config.vm.box_version = "34.20210423.0"
end


- With ssh-keygen public key created 

It'll deploy the following:

- Kubernetes Master (Fedora34)
- Kubernetes Node   (Fedora34)
- Vagrant 
- KVM 

Make sure you have a ssh public key on the target system your calling ansible on

Edit the ansible/inventory_file and enter the host you want to install vagrant on.
Run the command 
ansible-playbook -i ansible/inventory_file  ansible/playbooks/deploy-kvm-vagrant.yml --extra-vars "target=vagrant"
ansible-playbook -i ansible/inventory_file  ansible/playbooks/copy_ansible_deploy.yml --extra-vars "target=vagrant"
