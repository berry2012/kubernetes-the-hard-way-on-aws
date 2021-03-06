# kubernetes-the-hard-way-on-aws
**Setup Kubernetes the hard way on AWS**

*This is intended for audience that wants to understand how Kubernetes all fits together in AWS before going to production.* 

*In this tutorial, I deployed the infrastructure as code on AWS using AWS CloudFormation. I configured all the needed packages using Ansible for Configuration as Code.*


# Pre-requisites:
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) 
- [AWS Account](https://aws.amazon.com/premiumsupport/knowledge-center/create-and-activate-aws-account/)

# Cluster Details
- kubernetes v1.21.0
- containerd v1.4.4
- coredns v1.8.3
- cni v0.9.1
- etcd v3.4.15
- weavenetwork 

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

## Accessing the EC2 instances
- You can use SSH or AWS SSM to access the Ansible Server or any other node
- Connecting via [AWS SSM](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/session-manager.html) e.g.

`aws ssm start-session --target <instance-id>`

## Setting up for deployments
- Get instances and create Ansible inventory on your ansible controller server

> ```aws ec2 describe-instances --filters "Name=tag:project,Values=k8s-hardway" --query 'Reservations[*].Instances[*].[Placement.AvailabilityZone, State.Name, InstanceId, PrivateIpAddress, [Tags[?Key==`Name`].Value] [0][0]]' --output text --region eu-west-2```


- Define your environment variables

```
SSH_KEY_FILE="~/path/to/key.pem"

WORKER1_PRIVATE_IP=$(aws ec2 describe-instances --filters "Name=tag-value,Values=worker1" --query 'Reservations[*].Instances[*].[PrivateIpAddress]' --output text --region eu-west-2)    

WORKER2_PRIVATE_IP=$(aws ec2 describe-instances --filters "Name=tag-value,Values=worker2" --query 'Reservations[*].Instances[*].[PrivateIpAddress]' --output text --region eu-west-2)    

CONTROLLER1_PRIVATE_IP=$(aws ec2 describe-instances --filters "Name=tag-value,Values=controller1" --query 'Reservations[*].Instances[*].[PrivateIpAddress]' --output text --region eu-west-2)    

CONTROLLER2_PRIVATE_IP=$(aws ec2 describe-instances --filters "Name=tag-value,Values=controller2" --query 'Reservations[*].Instances[*].[PrivateIpAddress]' --output text --region eu-west-2)

CONTROLLER_API_LB_PRIVATE_IP=$(aws ec2 describe-instances --filters "Name=tag-value,Values=controller_api_server_lb" --query 'Reservations[*].Instances[*].[PrivateIpAddress]' --output text --region eu-west-2) 
```


- Confirm the Envrionment variables you've set

```
echo "CONTROLLER1_PRIVATE_IP=${CONTROLLER1_PRIVATE_IP}" 
echo "CONTROLLER2_PRIVATE_IP=${CONTROLLER2_PRIVATE_IP}"
echo "WORKER1_PRIVATE_IP=${WORKER1_PRIVATE_IP}"
echo "WORKER2_PRIVATE_IP=${WORKER2_PRIVATE_IP}"
echo "CONTROLLER_API_LB_PRIVATE_IP=${CONTROLLER_API_LB_PRIVATE_IP}"
echo "SSH_KEY_FILE=${SSH_KEY_FILE}"
```

- Copy the content of the `inventory` file and paste it on your terminal. 
  It will override the existing content and apply the environment variables.

- Transfer deployments/playbooks to ansible server

```
cd kubernetes-the-hard-way-on-aws/deployments

scp -i /path/to/key.pem *.yml *.yaml inventory *.cfg ubuntu@<ansible_server_public_ip>:~

scp -i /path/to/key.pem ../easy_script.sh ubuntu@<ansible_server_public_ip>:~

# transfer ssh key file
scp -i /path/to/key.pem /path/to/key.pem ubuntu@13.40.18.178:~/.ssh/

ssh -i /path/to/key.pem ubuntu@<ansible_server_public_ip>

chmod +x easy_script.sh

chmod 400 /path/to/key.pem
```



- After building the inventory file, test if all hosts are reachable

1.  list all hosts to confirm

    `ansible all --list-hosts -i inventory`

2.  Test ping on all the hosts

```
ansible -i inventory k8s -m ping --private-key ~/.ssh/key.pem
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
14. [Setup core DNS](./coreDNS.md)
15. `ansible-playbook -i inventory -v smoke_test.yml`



Results:
![Successful Controller Deployment ](./images/controller-deployment-test.png)


# Clean Up

*Delete the AWS CloudFormation Stack*

>`aws cloudformation delete-stack --stack-name k8s-hardway`


*Check if the AWS CloudFormation Stack still exist to confirm deletion* 

>`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region eu-west-1 --query 'StackSummaries[*].{Name:StackName,Date:CreationTime,Status:StackStatus}' --output text | grep k8s-hardway`