export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl delete clusterrole cf-operator
kubectl delete clusterrole cf-operator-quarks-job
kubectl delete clusterrolebinding cf-operator-quarks-job
kubectl delete clusterrolebinding cf-operator
kubectl delete podsecuritypolicy  kubecf-default

helm -n kubecf delete kubecf
helm -n cf-operator delete cf-operator
kubectl delete ns kubecf
kubectl delete ns cf-operator
