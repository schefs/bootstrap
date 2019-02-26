#!/bin/bash

# Deploy ingress controller

kubectl apply -f ingress-nginx-v1.6.0.yaml

# Deploy kube-promethues: grafana, prometheus operator, alert manager cluster

kubectl apply -f kube-prometheus/ || true
# It can take a few seconds for the above 'create manifests' command to fully create the following resources, so verify the resources are ready before proceeding.
until kubectl get customresourcedefinitions servicemonitors.monitoring.coreos.com ; do date; sleep 1; echo ""; done
until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done

kubectl apply -f kube-prometheus/ 2>/dev/null || true  # This command sometimes may need to be done twice (to workaround a race condition).

# Deploy heapster

kubectl apply -f heapster-v1.11.0.yaml

# Deploy kubernetes dashboard

 kubectl apply -f dashboard-v1.10.1.yaml

 # Deploy dummy exporter

 kubectl apply -f ../dummy_exporter/dummy_exporter.yaml

 # Deploy Fluentd and kibana
 
 kubectl apply -f fluentd-es-configmap.yaml -f fluentd-es-ds.yaml -f kibana-deployment.yaml -f kibana-service.yaml
 sed -r 's/(\b[0-9]{1,3}\.){3}[0-9]{1,3}\b'/$ES_IP_ADDRESS/ es-service.yaml| kubectl.exe apply -f -

 # Helm install consul

 kubectl apply -f tiller-rbac.yml
 helm init --service-account tiller
 sleep 20
 helm install --name consul --namespace consul ./consul-helm-0.6.0/

 # Deploy metrics-server

 #kubectl apply -f ./metrics-server/

 # Helm install Wordpress
 helm install stable/nfs-server-provisioner --set persistence.enabled=true,persistence.size=11Gi
 helm install --name wp --namespace default -f ./wp-values.yml stable/wordpress
 kubectl apply -f wp-hpa.yml