#!/bin/bash

# Deploy ingress controller

kubectl apply -f ingress-nginx-v1.6.0.yaml

# Deploy kube-promethues: grafana, prometheus operator, alert manager cluster

kubectl create -f kube-prometheus/ || true
# It can take a few seconds for the above 'create manifests' command to fully create the following resources, so verify the resources are ready before proceeding.
until kubectl get customresourcedefinitions servicemonitors.monitoring.coreos.com ; do date; sleep 1; echo ""; done
until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done

kubectl create -f kube-prometheus/ 2>/dev/null || true  # This command sometimes may need to be done twice (to workaround a race condition).

# Deploy heapster

kubectl apply -f heapster-v1.11.0.yaml

# Deploy kubernetes dashboard

 kubectl apply -f dashboard-v1.10.1.yaml

 # Deploy dummy exporter

 kubectl apply -f ../dummy_exporter/dummy_exporter.yaml
 
# Describe ingress resources IP addres
INGRESS=$(kubectl get svc -n ingress-controller -o jsonpath='{.items[*].status.loadBalancer.ingress[?(@.hostname)].*}')
echo -e "Ingress controller address is:\n\n$INGRESS"

# Dashboard access
DASHBOARD_PATH=/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/
SERVER=$(kubectl.exe config view -o=jsonpath='{.clusters[0].cluster.server}')
echo -e "K8s Dashboard UI is availabe in:\n $SERVER$DASHBOARD_PATH"



#