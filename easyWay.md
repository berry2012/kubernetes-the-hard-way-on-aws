
# Kubernetes the hard way on AWS made easy

**This is an easier option: After preparing the Ansible inventory, execute the command below:**

`ubuntu@ip-10-192-10-137:~$ bash easy_script.sh`

output:
```
TASK [Get logs from pod] ****************************************************************
changed: [localhost] => {"changed": true, "cmd": "POD_NAME=$(kubectl get pods -l run=nginx -o jsonpath=\"{.items[0].metadata.name}\")\nkubectl exec -i $POD_NAME -- nginx -v\n", "delta": "0:00:00.265038", "end": "2022-05-06 20:19:15.959191", "rc": 0, "start": "2022-05-06 20:19:15.694153", "stderr": "nginx version: nginx/1.21.6", "stderr_lines": ["nginx version: nginx/1.21.6"], "stdout": "", "stdout_lines": []}

PLAY RECAP ******************************************************************************
controller1                : ok=2    changed=1    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0   
localhost                  : ok=8    changed=5    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0   


easy deployment completed!!!


ubuntu@ip-10-192-10-137:~$ kubectl get nodes
NAME      STATUS   ROLES    AGE   VERSION
worker1   Ready    <none>   15m   v1.21.0
worker2   Ready    <none>   14m   v1.21.0
ubuntu@ip-10-192-10-137:~$ 
```

