#!/bin/sh
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl get pods -n kubecf |  cut -d" " -f1 | xargs -n1 kubectl -n kubecf delete pod
