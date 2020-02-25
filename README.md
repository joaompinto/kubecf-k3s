# kubecf-k3s

This repository provides a script for deploying CloudFoundry ([kubecf]) using k3s.

The script installs the following tools:
 - [k3s], disabling traefik and servicelb to avoid node port conflicts
 - [helm]


[k3s]: https://k3s.io/
[helm]: https://helm.sh/
[kubecf]: https://github.com/SUSE/kubecf

## How to use

```sh
./k3s-deploy-cf.sh
```

## Connecting to the CF API
```sh
cf api --skip-ssl-validation api.192.168.0.15.nip.io

# Authenticating with th e admin password
admin_pass=$(kubectl get secret \
        --namespace kubecf kubecf.var-cf-admin-password \
        -o jsonpath='{.data.password}' \
        | base64 --decode)
cf auth admin "${admin_pass}"
```
## Known issues

After rebooting the k3s host system you may need to use k3s-restart-cf.sh to get all the pods in n healthy state