# kubernetes-the-hard-way-on-aws
**Setup Kubernetes the hard way on AWS**

*This is intended for audience that wants to understand how Kubernetes all fits together in AWS before going to production.* 

*In this tutorial, I deployed the infrastructure as code on AWS using AWS CloudFormation. I configured all the needed packages using Ansible for Configuration as Code.*


# Pre-requisites:
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) 
- [AWS Account](https://aws.amazon.com/premiumsupport/knowledge-center/create-and-activate-aws-account/)

# Cluster Details
- kubernetes v1.23.9
- containerd v1.6.8
- coredns v1.9.3
- cni v1.1.1
- etcd v3.4.20
- weavenetwork 1.23

## Node Details
- All the provisioned instances run the same OS

```
ubuntu@ip-10-192-10-110:~$ cat /etc/os-release 
NAME="Ubuntu"
VERSION="20.04.4 LTS (Focal Fossa)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 20.04.4 LTS"
VERSION_ID="20.04"
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
VERSION_CODENAME=focal
UBUNTU_CODENAME=focal

```
# Usage Instructions


## Deploying the Infrastructure with CloudFormation

- Goto AWS Console > Choose Region (e.g. eu-west-1) > CloudFormation > Create Stack
- Use the CF Yaml template in *infrastructure/k8s_aws_instances.yml*
- See image below:

![Create Infrastructure](./images/CF-infrastructure.png) 



## 1. Accessing the EC2 instances
- Define your global variables
```
export LOCAL_SSH_KEY_FILE="~/.ssh/key.pem"
export REGION="eu-west-2"
```

## Setting up for deployments
- Confirm the instances created and the Public IP of the Ansible controller server

```
aws ec2 describe-instances --filters "Name=tag:project,Values=k8s-hardway" --query 'Reservations[*].Instances[*].[Placement.AvailabilityZone, State.Name, InstanceId, PrivateIpAddress, PublicIpAddress, [Tags[?Key==`Name`].Value] [0][0]]' --output text --region ${REGION}

```
- Define your Ansible server environment variable
```
  export ANSIBLE_SERVER_PUBLIC_IP=""
```

- You can use SSH or AWS SSM to access the Ansible Controller Server or any other nodes that were created with the CloudFormation Template
- Connecting via [AWS SSM](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/session-manager.html) e.g.


```
aws ssm start-session --target <instance-id> --region ${REGION}
```

- Transfer your SSH key to the Ansible Server. This will be need in the Ansible Inventory file.
  
```
echo "scp -i ${LOCAL_SSH_KEY_FILE} ${LOCAL_SSH_KEY_FILE} ubuntu@${ANSIBLE_SERVER_PUBLIC_IP}:~/.ssh/" 
inspect and execute the output
```



- To Create inventory file. Edit the inventory.sh and update the variable SSH_KEY_FILE and REGION accordingly

```
vi deployments/inventory.sh
chmod +x deployments/inventory.sh
bash deployments/inventory.sh

```

- Transfer all playbooks in deployments/playbooks to the ansible server

```
cd kubernetes-the-hard-way-on-aws/deployments

scp -i ${LOCAL_SSH_KEY_FILE} *.yml *.yaml ../inventory *.cfg ubuntu@${ANSIBLE_SERVER_PUBLIC_IP}:~

scp -i ${LOCAL_SSH_KEY_FILE} ../easy_script.sh ubuntu@${ANSIBLE_SERVER_PUBLIC_IP}:~

```

- Connect to the Ansible Server
```
ssh -i ${LOCAL_SSH_KEY_FILE} ubuntu@${ANSIBLE_SERVER_PUBLIC_IP}

chmod +x easy_script.sh

LOCAL_SSH_KEY_FILE="~/.ssh/key.pem"  # your ssh key

chmod 400 ${LOCAL_SSH_KEY_FILE}
```



- After building the inventory file, test if all hosts are reachable

1.  list all hosts to confirm that the inventory file is properly configured

```
ansible all --list-hosts -i inventory

  hosts (5):
    controller1
    controller2
    worker1
    worker2
    controller_api_server_lb

```

2.  Test ping on all the hosts

```
ansible -i inventory k8s -m ping 

worker1 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
controller_api_server_lb | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
controller2 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
controller1 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
worker2 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
ubuntu@ip-10-192-10-137:~$ 

```

## Configuring the Servers with Ansible
**From the Ansible server, execute the Ansible playbook in the following order or For an easier 1 click deployment option, see [instruction](./easyWay.md)**


1. `ansible-playbook -i inventory -v client_tools.yml`
2. `ansible-playbook -i inventory -v cert_vars.yml`
3. `cat variables.text >> env.yaml`
4. `ansible-playbook -i inventory -v create_ca_certs.yml`
5. `ansible-playbook -i inventory -v create_kubeconfigs.yml`
6. `ansible-playbook -i inventory -v distribute_k8s_files.yml`
7. `ansible-playbook -i inventory -v deploy_etcd_cluster.yml`
8. `ansible-playbook -i inventory -v deploy_api-server.yml` See results below.
9. `ansible-playbook -i inventory -v rbac_authorization.yml`
10. `ansible-playbook -i inventory -v deploy_nginx.yml`
11. `ansible-playbook -i inventory -v workernodes.yml`
12. `ansible-playbook -i inventory -v kubectl_remote.yml`
13. `ansible-playbook -i inventory -v deploy_weavenet.yml`
14. [Setup coreDNS](./coreDNS.md)
15. `ansible-playbook -i inventory -v smoke_test.yml`



Results:
![Successful Controller Deployment ](./images/controller-deployment-test.png)


# Clean Up

*Delete the AWS CloudFormation Stack*

>`aws cloudformation delete-stack --stack-name k8s-hardway`


*Check if the AWS CloudFormation Stack still exist to confirm deletion* 

>`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region eu-west-1 --query 'StackSummaries[*].{Name:StackName,Date:CreationTime,Status:StackStatus}' --output text | grep k8s-hardway`




