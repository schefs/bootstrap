#!/bin/bash

export KOPS_STATE_STORE=s3://$(terraform output kops_s3_state_bucket)
export KOPS_CLUSTER_NAME=$(terraform output dns_zone_name)
export ES_IP_ADDRESS=$(terraform output es_address)

kops create cluster \
     --cloud=aws \
     --state=$KOPS_STATE_STORE \
     --node-count 3 \
     --zones $(terraform.exe output AZ |tr -d '\n') \
     --master-zones $(terraform.exe output AZ |tr -d '\n') \
     --dns-zone=$(terraform output dns_zone_id) \
     --vpc=$(terraform output vpc_id) \
     --dns private \
     --node-size t2.medium \
     --master-size t2.medium \
     --topology private \
     --networking calico \
     --bastion \
     --ssh-public-key ~/.ssh/id_rsa.pub \
     --cloud-labels $(terraform output common_tags|tr '\n' ','|sed 's/ //g'|sed 's/.$//') \
     --name $KOPS_CLUSTER_NAME

