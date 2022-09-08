#!/bin/bash

REGION=eu-west-2 # update this if needed
SSH_KEY_FILE="~/path/to/key.pem"  # update this

# get variables
WORKER1_PRIVATE_IP=$(aws ec2 describe-instances --filters "Name=tag-value,Values=worker1" --query 'Reservations[*].Instances[*].[PrivateIpAddress]' --output text --region ${REGION})    
WORKER2_PRIVATE_IP=$(aws ec2 describe-instances --filters "Name=tag-value,Values=worker2" --query 'Reservations[*].Instances[*].[PrivateIpAddress]' --output text --region ${REGION})    
CONTROLLER1_PRIVATE_IP=$(aws ec2 describe-instances --filters "Name=tag-value,Values=controller1" --query 'Reservations[*].Instances[*].[PrivateIpAddress]' --output text --region ${REGION})    
CONTROLLER2_PRIVATE_IP=$(aws ec2 describe-instances --filters "Name=tag-value,Values=controller2" --query 'Reservations[*].Instances[*].[PrivateIpAddress]' --output text --region ${REGION})
CONTROLLER_API_LB_PRIVATE_IP=$(aws ec2 describe-instances --filters "Name=tag-value,Values=controller_api_server_lb" --query 'Reservations[*].Instances[*].[PrivateIpAddress]' --output text --region ${REGION}) 


# - Confirm the Envrionment variables you've set

echo "CONTROLLER1_PRIVATE_IP=${CONTROLLER1_PRIVATE_IP}" 
echo "CONTROLLER2_PRIVATE_IP=${CONTROLLER2_PRIVATE_IP}"
echo "WORKER1_PRIVATE_IP=${WORKER1_PRIVATE_IP}"
echo "WORKER2_PRIVATE_IP=${WORKER2_PRIVATE_IP}"
echo "CONTROLLER_API_LB_PRIVATE_IP=${CONTROLLER_API_LB_PRIVATE_IP}"
echo "SSH_KEY_FILE=${SSH_KEY_FILE}"


# create ansible inventory file
cat << EOF | tee inventory
[k8s]
controller1     ansible_host=${CONTROLLER1_PRIVATE_IP}    ansible_connection=ssh      ansible_user=ubuntu   ansible_ssh_private_key_file="${SSH_KEY_FILE}"    ansible_become=yes    
controller2     ansible_host=${CONTROLLER2_PRIVATE_IP}  ansible_connection=ssh      ansible_user=ubuntu   ansible_ssh_private_key_file="${SSH_KEY_FILE}"    ansible_become=yes
worker1         ansible_host=${WORKER1_PRIVATE_IP}  ansible_connection=ssh      ansible_user=ubuntu   ansible_ssh_private_key_file="${SSH_KEY_FILE}"    ansible_become=yes
worker2         ansible_host=${WORKER2_PRIVATE_IP}    ansible_connection=ssh      ansible_user=ubuntu   ansible_ssh_private_key_file="${SSH_KEY_FILE}"    ansible_become=yes
controller_api_server_lb  ansible_host=${CONTROLLER_API_LB_PRIVATE_IP} ansible_connection=ssh      ansible_user=ubuntu   ansible_ssh_private_key_file="${SSH_KEY_FILE}"    ansible_become=yes

[controllers]
controller1     ansible_host=${CONTROLLER1_PRIVATE_IP}    ansible_connection=ssh      ansible_user=ubuntu   ansible_ssh_private_key_file="${SSH_KEY_FILE}"    ansible_become=yes    
controller2     ansible_host=${CONTROLLER2_PRIVATE_IP}  ansible_connection=ssh      ansible_user=ubuntu   ansible_ssh_private_key_file="${SSH_KEY_FILE}"    ansible_become=yes

[workers]
worker1         ansible_host=${WORKER1_PRIVATE_IP}  ansible_connection=ssh      ansible_user=ubuntu   ansible_ssh_private_key_file="${SSH_KEY_FILE}"    ansible_become=yes
worker2         ansible_host=${WORKER2_PRIVATE_IP}    ansible_connection=ssh      ansible_user=ubuntu   ansible_ssh_private_key_file="${SSH_KEY_FILE}"    ansible_become=yes

[lb]
controller_api_server_lb  ansible_host=${CONTROLLER_API_LB_PRIVATE_IP} ansible_connection=ssh      ansible_user=ubuntu   ansible_ssh_private_key_file="${SSH_KEY_FILE}"    ansible_become=yes
EOF