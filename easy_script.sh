#!/bin/bash

set -o pipefail
set -o errexit

echo "Install Client Tools"
ansible-playbook -i inventory -v client_tools.yml
echo "Prepare variables needed for Certificates"
ansible-playbook -i inventory -v cert_vars.yml
echo "Update the existing environment variable files"
cat variables.text >> env.yaml
echo "Provision the CA and generate TLS certificates"
ansible-playbook -i inventory -v create_ca_certs.yml
echo "Generate Kubernetes Configuration files"
ansible-playbook -i inventory -v create_kubeconfigs.yml
echo "Distribute the Kubernetes configuration files to all nodes"
ansible-playbook -i inventory -v distribute_k8s_files.yml
echo "Bootsrap etcd cluster"
ansible-playbook -i inventory -v deploy_etcd_cluster.yml
echo "Bootsrap the Kubernetes Control plane"
ansible-playbook -i inventory -v deploy_api-server.yml
ansible-playbook -i inventory -v rbac_authorization.yml
ansible-playbook -i inventory -v deploy_nginx.yml
echo "Bootsrap the Kubernetes Workernodes"
ansible-playbook -i inventory -v workernodes.yml
echo "Configuring kubectl for Remote Access"
ansible-playbook -i inventory -v kubectl_remote.yml
echo "Configure Networking"
ansible-playbook -i inventory -v deploy_weavenet.yml
echo "Deploy DNS Cluster Add-ons"
kubectl apply -f https://storage.googleapis.com/kubernetes-the-hard-way/coredns-1.8.yaml
sleep 15
kubectl get pods -l k8s-app=kube-dns -n kube-system
echo "Perform Smoke Test in the cluster"
ansible-playbook -i inventory -v smoke_test.yml
echo "easy deployment completed!!!"
