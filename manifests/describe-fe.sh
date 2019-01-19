#!/bin/bash

SERVER=$(kubectl.exe config view -o=jsonpath='{.clusters[0].cluster.server}')

# Describe ingress resources IP addres
INGRESS=$(kubectl get svc -n kube-ingress -o jsonpath='{.items[*].status.loadBalancer.ingress[?(@.hostname)].*}')
echo -e "Ingress controller address is:\n\e[32m$INGRESS"
echo -e "\e[0mDummy Exporter is available in :\n\e[32mhttps://$INGRESS/dummy-exporter"

# Grafana service
GRAFANA=$(kubectl get svc -n monitoring grafana -o jsonpath='{.status.loadBalancer.ingress[?(@.hostname)].*}')
echo -e "\e[0mGrafana UI is available in :\n\e[32mhttp://$GRAFANA:3000"

 # Kibana service
KIBANA_PATH=/api/v1/namespaces/monitoring/services/kibana-logging/proxy/app/kibana
echo -e "\e[0mKibana UI is availabe in:\n\e[32m$SERVER$DASHBOARD_PATH"

# Dashboard access
DASHBOARD_PATH=/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/
echo -e "\e[0mK8s Dashboard UI is availabe in:\n\e[32m$SERVER$DASHBOARD_PATH"