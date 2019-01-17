#!/bin/bash

# Deploy ingress controller

kubectl apply -f haproxy-ingress.yaml

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
 
# Describe ingress resources
INGRESS=$(kubectl get svc -n ingress-controller -o jsonpath='{.items[*].status.loadBalancer.ingress[?(@.hostname)].*}')
echo -e "Ingress controller address is:\n\n$INGRESS"
echo -e "grafana is available in:\n$INGRESS/grafana"

#