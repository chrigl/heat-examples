# Setting up a kubernetes cluster

Dependency: `make` and `openssl`

This installation expects to have access to OpenStack. You have to move `openstack.conf.sample` to `openstack.conf` and place credentails into this file. If you do *not* want to connect kubernetes to OpenStack, you have to remove `--cloud-config=/etc/kubernetes/cloud/openstack.conf` from `kubernetes/master/manifests/kube-controller-manager.yaml`, `kubernetes/master/node.yaml` and `kubernetes/worker/node.yaml`. You could also remove the `write_files` of `/etc/kubernetes/cloud/openstack.conf` from `kubernetes/master/node.yaml` and `kubernetes/worker/node.yaml`. If `openstack.conf.sample`, or another error is in this file, kubernetes refuses to start. If you get an error like `Could not fetch contents for file:///Users/chris/heat-examples/coreos/kubernetes/openstack.conf`, there is some remainig `write_files` in some some yaml.


First of all, you need to configure your public_net_id in `01-network-stack-env.yaml`, and setup the network. Also replace the `key name` in all the `*-env.yml`-files, or use `-P key_name=YOUR_KEY` with `heat`.

```
$ heat stack-create -f 01-network-stack.yaml -e 01-network-stack-env.yaml kubi
$ heat stack-list
+--------------------------------------+------------+-----------------+----------------------+--------------+
| id                                   | stack_name | stack_status    | creation_time        | updated_time |
+--------------------------------------+------------+-----------------+----------------------+--------------+
| fff0ba44-9e2e-4ea5-91d2-6f19c7fabf30 | kubi       | CREATE_COMPLETE | 2016-06-24T13:05:38Z | None         |
+--------------------------------------+------------+-----------------+----------------------+--------------+
```

Getting the network, subnet_id and floating_ip_id

```
$ heat resource-list kubi
+-----------------------+-------------------------------------------------------------------------------------+------------------------------+-----------------+----------------------+
| resource_name         | physical_resource_id                                                                | resource_type                | resource_status | updated_time         |
+-----------------------+-------------------------------------------------------------------------------------+------------------------------+-----------------+----------------------+
| kube_floating_ip      | cb87f842-e68e-4971-8894-3ca0cb2903e1                                                | OS::Neutron::FloatingIP      | CREATE_COMPLETE | 2016-06-24T13:05:38Z |
| network               | edb65d20-5432-4dbc-9a25-fd448924e036                                                | OS::Neutron::Net             | CREATE_COMPLETE | 2016-06-24T13:05:38Z |
| router                | 5890aafe-6c22-4fd5-bcca-1a31a53e6397                                                | OS::Neutron::Router          | CREATE_COMPLETE | 2016-06-24T13:05:38Z |
| router_subnet_connect | 5890aafe-6c22-4fd5-bcca-1a31a53e6397:subnet_id=a2395fb2-1412-4b38-a608-dcc0304ba64f | OS::Neutron::RouterInterface | CREATE_COMPLETE | 2016-06-24T13:05:38Z |
| subnet                | a2395fb2-1412-4b38-a608-dcc0304ba64f                                                | OS::Neutron::Subnet          | CREATE_COMPLETE | 2016-06-24T13:05:38Z |
+-----------------------+-------------------------------------------------------------------------------------+------------------------------+-----------------+----------------------+
```

and adjust the values of `network` and `subnet` in `02-etcd-stack-env.yaml`.


The etcd-cluster is the first real component to create

```
$ heat stack-create -f 02-etcd-stack.yaml -e 02-etcd-stack-env.yaml -P discovery_url=(curl "https://discovery.etcd.io/new?size=5") kubi-etcd
$ nova list
+--------------------------------------+-------------+--------+------------+-------------+-----------------------------------+
| ID                                   | Name        | Status | Task State | Power State | Networks                          |
+--------------------------------------+-------------+--------+------------+-------------+-----------------------------------+
| ca0f0a06-11dc-483a-99d2-ce047d070038 | kubi-etcd0  | ACTIVE | -          | Running     | kubi-kubernetes-network=10.0.0.10 |
| 46d3985e-526c-4d38-9417-6c4eb820c1ef | kubi-etcd1  | ACTIVE | -          | Running     | kubi-kubernetes-network=10.0.0.11 |
| d25f8bbe-d392-4bb0-a0e2-eccbdb9e8de8 | kubi-etcd2  | ACTIVE | -          | Running     | kubi-kubernetes-network=10.0.0.12 |
| c10597f1-b6e0-404c-9160-b0a2af6afe20 | kubi-etcd3  | ACTIVE | -          | Running     | kubi-kubernetes-network=10.0.0.13 |
| 04a202b4-2f9d-4fc2-88e4-31eb90e056cc | kubi-etcd4  | ACTIVE | -          | Running     | kubi-kubernetes-network=10.0.0.14 |
+--------------------------------------+-------------+--------+------------+-------------+-----------------------------------+
```

Edit `03-kubernetes-master-stack-env.yaml` and `04-kubernetes-worker-stack-env.yml` in the same way as `02-etcd-stack-env.yaml`, but also adjust the `etcd endpoints`.


Now, you can create the necessary TLS CA and stuff, by calling `make`

```
$ make
/Applications/Xcode.app/Contents/Developer/usr/bin/make -C tls all
openssl genrsa -out ca-key.pem 2048
Generating RSA private key, 2048 bit long modulus
...........+++
[...]
```


Start the kubernetes master:

```
$ heat stack-create -f 03-kubernetes-master-stack.yaml -e 03-kubernetes-master-stack-env.yaml kubi-master
$ nova list
+--------------------------------------+--------------------------------+--------+------------+-------------+-------------------------------------------------+
| ID                                   | Name                           | Status | Task State | Power State | Networks                                        |
+--------------------------------------+--------------------------------+--------+------------+-------------+-------------------------------------------------+
| ca0f0a06-11dc-483a-99d2-ce047d070038 | kubi-etcd0                     | ACTIVE | -          | Running     | kubi-kubernetes-network=10.0.0.10               |
| 46d3985e-526c-4d38-9417-6c4eb820c1ef | kubi-etcd1                     | ACTIVE | -          | Running     | kubi-kubernetes-network=10.0.0.11               |
| d25f8bbe-d392-4bb0-a0e2-eccbdb9e8de8 | kubi-etcd2                     | ACTIVE | -          | Running     | kubi-kubernetes-network=10.0.0.12               |
| c10597f1-b6e0-404c-9160-b0a2af6afe20 | kubi-etcd3                     | ACTIVE | -          | Running     | kubi-kubernetes-network=10.0.0.13               |
| 04a202b4-2f9d-4fc2-88e4-31eb90e056cc | kubi-etcd4                     | ACTIVE | -          | Running     | kubi-kubernetes-network=10.0.0.14               |
| 348680fd-359b-42dc-9c31-a3e24d427c75 | kubi-master0                   | ACTIVE | -          | Running     | kubi-kubernetes-network=10.0.0.20,77.247.85.192 |
+--------------------------------------+--------------------------------+--------+------------+-------------+-------------------------------------------------+
```


In the meantime, you should setup kubectl on your host

```
> cat ~/.kube/config
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /Users/chris/heat-examples/coreos/kubernetes/tls/ca.pem
    server: https://kubernetes-master
  name: default-cluster
contexts:
- context:
    cluster: default-cluster
    user: default-admin
  name: default-system
current-context: default-system
kind: Config
preferences: {}
users:
- name: default-admin
  user:
    client-certificate: /Users/chris/heat-examples/coreos/kubernetes/tls/admin.pem
    client-key: /Users/chris/heat-examples/coreos/kubernetes/tls/admin-key.pem
```

And add `kubernetes-master` to your `/etc/hosts`

```
$ neutron floatingip-show cb87f842-e68e-4971-8894-3ca0cb2903e1
+---------------------+--------------------------------------+
| Field               | Value                                |
+---------------------+--------------------------------------+
| fixed_ip_address    | 10.0.0.20                            |
| floating_ip_address | 77.247.85.192                        |
| floating_network_id | 4c23774c-395b-49d0-b8e1-347e886fa9bf |
| id                  | cb87f842-e68e-4971-8894-3ca0cb2903e1 |
| port_id             | 67e53c1f-2091-4fbf-9bd4-1dd56ce354fc |
| router_id           | 5890aafe-6c22-4fd5-bcca-1a31a53e6397 |
| status              | ACTIVE                               |
| tenant_id           | 581c84aa48414abd8066a6ef69cee99a     |
+---------------------+--------------------------------------+

$ vi /etc/hosts
77.247.85.192 kubernetes-master
```

Your cluster should be up an running

```
$ kubectl cluster-info
Kubernetes master is running at https://kubernetes-master
$ kubectl get nodes
NAME           STATUS                     AGE
kubi-master0   Ready,SchedulingDisabled   4m
```

Now, create the namespace `kube-system`

```
$ kubectl create namespace kube-system
namespace "kube-system" created
```

After a while, all the kubernetes management pods show show up

```
$ kubectl get pods --namespace kube-system
NAME                                   READY     STATUS    RESTARTS   AGE
kube-apiserver-kubi-master0            1/1       Running   0          1m
kube-controller-manager-kubi-master0   1/1       Running   0          8s
kube-proxy-kubi-master0                1/1       Running   0          40s
kube-scheduler-kubi-master0            1/1       Running   0          1m
```

Start the worker nodes

```
$ heat stack-create -f 04-kubernetes-worker-stack.yaml  -e 04-kubernetes-worker-stack-env.yaml -P count=10 kubi-worker
$ nova list
+--------------------------------------+--------------------------------+--------+------------+-------------+-------------------------------------------------+
| ID                                   | Name                           | Status | Task State | Power State | Networks                                        |
+--------------------------------------+--------------------------------+--------+------------+-------------+-------------------------------------------------+
| ca0f0a06-11dc-483a-99d2-ce047d070038 | kubi-etcd0                     | ACTIVE | -          | Running     | kubi-kubernetes-network=10.0.0.12               |
| 46d3985e-526c-4d38-9417-6c4eb820c1ef | kubi-etcd1                     | ACTIVE | -          | Running     | kubi-kubernetes-network=10.0.0.11               |
| d25f8bbe-d392-4bb0-a0e2-eccbdb9e8de8 | kubi-etcd2                     | ACTIVE | -          | Running     | kubi-kubernetes-network=10.0.0.14               |
| c10597f1-b6e0-404c-9160-b0a2af6afe20 | kubi-etcd3                     | ACTIVE | -          | Running     | kubi-kubernetes-network=10.0.0.13               |
| 04a202b4-2f9d-4fc2-88e4-31eb90e056cc | kubi-etcd4                     | ACTIVE | -          | Running     | kubi-kubernetes-network=10.0.0.15               |
| 348680fd-359b-42dc-9c31-a3e24d427c75 | kubi-master0                   | ACTIVE | -          | Running     | kubi-kubernetes-network=10.0.0.20,77.247.85.192 |
| 59392ce1-e8d0-4f0f-8b4d-fae2b36a7465 | kubi-worker0                   | ACTIVE | -          | Running     | kubi-kubernetes-network=10.4.0.2                |
| 65f63ff0-ed87-432f-8326-bb290793681a | kubi-worker1                   | ACTIVE | -          | Running     | kubi-kubernetes-network=10.4.0.3                |
| f637687e-a7c7-4da9-8180-031e747f0096 | kubi-worker2                   | ACTIVE | -          | Running     | kubi-kubernetes-network=10.4.0.4                |
| ...                                  | ...                            | ...    | ...        | ...         | ...                                             |
| f5dae297-5f13-49cf-80d0-5a97d4dff894 | kubi-workerN                   | ACTIVE | -          | Running     | kubi-kubernetes-network=10.4.9.N                |
+--------------------------------------+--------------------------------+--------+------------+-------------+-------------------------------------------------+
```

Again after a short while, the worker nodes should show up

```
> kubectl get nodes
NAME          STATUS                     AGE
kubi-worker0  Ready                      1m
kubi-worker1  Ready                      1m
kubi-master0  Ready,SchedulingDisabled   6m
kubi-worker2  Ready                      1m
kubi-workerN  Ready                      45s
```
