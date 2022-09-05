

# Setup CoreDNS and Test

**Follow the steps below to setup core DNS in the kubernetes cluster from the ansible server as kubectl remote host**


```[ubuntu@ip-192-168-91-186 ~]$ kubectl apply -f https://raw.githubusercontent.com/berry2012/kubernetes-the-hard-way-on-aws/release-1.23.9/coredns-1.9.3.yaml

[ubuntu@ip-192-168-91-186 ~]$ kubectl get pods -l k8s-app=kube-dns -n kube-system
NAME                       READY   STATUS    RESTARTS   AGE
coredns-8494f9c688-hr5hq   1/1     Running   0          18s
coredns-8494f9c688-wxp2r   1/1     Running   0          18s

[ubuntu@ip-192-168-91-186 ~]$ kubectl run busybox --image=busybox:1.28 --command -- sleep 3600
pod/busybox created

[ubuntu@ip-192-168-91-186 ~]$ kubectl get pods -l run=busybox
NAME      READY   STATUS    RESTARTS   AGE
busybox   1/1     Running   0          8s

[ubuntu@ip-192-168-91-186 ~]$ kubectl exec -ti busybox -- nslookup kubernetes
Server:    10.32.0.10
Address 1: 10.32.0.10 kube-dns.kube-system.svc.cluster.local

Name:      kubernetes
Address 1: 10.32.0.1 kubernetes.default.svc.cluster.local
[ubuntu@ip-192-168-91-186 ~]$ 

[ubuntu@ip-192-168-91-186 ~]$ kubectl exec -it busybox -- cat /etc/resolv.conf
search default.svc.cluster.local svc.cluster.local cluster.local eu-west-1.compute.internal
nameserver 10.32.0.10
options ndots:5
[ubuntu@ip-192-168-91-186 ~]$ 

```