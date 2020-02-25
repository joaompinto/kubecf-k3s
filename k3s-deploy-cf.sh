# Install k3s with the kubeconfig readable for everyone
K3S_OPTIONS="--node-name cfnode --write-kubeconfig-mode 0644\
    --no-deploy traefik --no-deploy servicelb"
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="$K3S_OPTIONS" sh -

# Install Helm 3
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get-helm-3 | sh -

# Make sure we use the kubctl provided by k3s
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

node_ip=$(kubectl get node cfnode \
    --output jsonpath='{ .status.addresses[?(@.type == "InternalIP")].address }')

# Create the NS for the cf-operator
kubectl create ns cf-operator

version="2.3.0%2B0.g27a91cdf"
helm install cf-operator \
    --namespace cf-operator \
    --set "global.operator.watchNamespace=kubecf" \
    https://s3.amazonaws.com/cf-operators/release/helm-charts/cf-operator-${version}.tgz

cat << _EOF_  > values.yaml
system_domain: ${node_ip}.nip.io
services:
    router:
        externalIPs:
            - ${node_ip}
kube:
    service_cluster_ip_range: 0.0.0.0/0
    pod_cluster_ip_range: 0.0.0.0/0
_EOF_

running_pods=0
while [[ "$running_pods" != "2" ]];
do
    echo "Waiting 20s for the two cf-operator pods to be running..."
    sleep 20
    running_pods=$(kubectl get pods -n cf-operator | grep -c Running)
    echo "Running pods=$running_pods"
done


helm install kubecf \
    --namespace kubecf \
    --values values.yaml \
    https://scf-v3.s3.amazonaws.com/kubecf-v0.0.0-e7534b6.tgz


running_pods=0
while [[ "$running_pods" != "1" ]];
do
    echo "Waiting 120s for the kubecf-database pod to be running..."
    sleep 120s
    running_pods=$(kubectl -n kubecf get pods | egrep -c "^kubecf-database")
    echo "Running databse pods=$running_pods"
done
echo "Patching the database statefulset"
kubectl -n kubecf patch StatefulSet/kubecf-database --type json --patch '[{ "op": "remove", "path": "/spec/template/spec/containers/0/livenessProbe" }]'
kubectl -n kubecf patch StatefulSet/kubecf-database --type json --patch '[{ "op": "remove", "path": "/spec/template/spec/containers/0/readinessProbe" }]'
echo "Waiting 120s for the database to be available"
sleep 120
echo "Restarting pods that were not yet started"
kubectl get pods -n kubecf | egrep "Init|CrashLoopBack|Error" | cut -d" " -f1 | xargs -n1 kubectl -n kubecf delete pod


running_pods=0
while [[ "$running_pods" != "19" ]];
do
    echo "Waiting 120s for the 19 kubecf pods to be running..."
    sleep 120
    running_pods=$(kubectl -n kubecf get pods  | grep -c "Running")
    echo "Running pods=$running_pods"
done
kubectl -n kubecf get pods