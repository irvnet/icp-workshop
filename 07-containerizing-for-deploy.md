
## Containerizing a process for deployment

**In this section**, you will learn how to capture a simple node.js process in a docker container to run on the platform. In addition you'll learn how to wrap a docker image in a helm chart for deployment from the catalog.

Containers are virtual software objects that include the parts an application requires for execution. A container includes the operating system that provides isolation for the application process, as well as its dependencies.

For those needing an introduction on Docker, please consult https://docs.docker.com.

> **Tasks**:
>- [Prerequisites](#prerequisites)
- [Task 1: Create a simple node process](#task-1-create-a-simple-node-process)
- [Task 2: Deploy rom the ICP cluster image repository](#task-2-deploy-from-the-ICP-cluster-image-repository)
- [Task 3: Push an updated image to the ICP image repository](#task-3-push-an-updated-image-to-the-image-repository)
- [Task 4: Deploying the sample process as a helm chart](#task-4-deploying-the-sample-process-helm-cart)
- [Task 5: Uploading the chart to the ICP catalog](#task-5-uploading-the-chart-to-the-ICP-catalog)
Task 5: Uploading the chart to the ICP catalog

## Understanding the pre-requsites

## Task 1: Create a simple node.js process

In this section we'll create a simple node.js process and wrap it in a docker container. After testing that the container works locally as expected, we'll push the container to the  IBM Cloud Private registry and run it in our environment.


1. create server.js using your preferred editor and add the following code:
```
  var http = require('http');

  var handleRequest = function(request, response) {
  console.log('Received request for URL: ' + request.url);
  response.writeHead(200);
  response.end('Hello World!');
  };
  var www = http.createServer(handleRequest);
  www.listen(8080);
```

2. Create Dockerfile and enter the following code

```
  FROM node:6.9.2
  EXPOSE 8080
  COPY server.js .
  CMD node server.js
```

3. Build the Docker image
```
$ docker build -t mynode:v1.0 .
```

4. Run the image and test it locally

```
$ docker run --rm -d -p 8080:8080 --name mynode-sample  hello-node:v1
```

  For a quick test of the container running locally on your machine, In your browser, access http://localhost:8080.  

5. Stop the locally running container

```  
$ docker stop mynode-sample
```


---

## Task 2: Deploy rom the ICP cluster image repository

1. login to the cluster repo (username: admin / pwd: admin)

```
$ docker login mycluster.icp:8500
```


2. Tag the image for pushing to the cluster's image repo

```
$ docker tag hello-node:v1 mycluster.icp:8500/default/hello-node:v1

$ docker push mycluster.icp:8500/default/hello-node:v1
```


3. Edit the image to change the scope from namespace to global so anyone can run it

```
kubectl edit image hello-node -n default

```

4. Run the image from the command line and see the available deployment in the dashboard

```
kubectl run irvnet-hello-my-node --image=mycluster.icp:8500/default/hello-node:v1 --port=8080
```


5. Expose the pod to the internet by creating a service

```
kubectl expose deployment irvnet-hello-node --type=LoadBalancer
```


6. find the new service and get the new port
```
kubectl get services
```


7. scale the deployment

```
kubectl scale deployment irvnet-hello-my-node --replicas=5
```

8. Update the application to have different output... for our 2nd version

9. Build v2 of the application

```
docker build -t hello-node:v2 .
```

Summary: The image with the node process has been tested on the ICP cluster showing several capabilities that deployments offer.

---

## Task 3:  Push an updated image to the ICP image repository

1. tag the image and push to the cluster's image repo

```
docker tag hello-node:v2 mycluster.icp:8500/default/hello-node:v2
docker push mycluster.icp:8500/default/hello-node:v2
```

2. deploy the updated version to the cluster
```
kubectl set image deployment/irvnet-hello-my-node  irvnet-hello-my-node=mycluster.icp:8500/default/hello-node:v2
```

3. curl the open port to see the updated message

4. rollback to version 1
```
kubectl rollout undo deployment/irvnet-hello-my-node
```

5. cleanup
```
kubectl delete deployment irvnet-hello-my-node
```

---

## Task 4: Deploying the sample process as a helm chart

1. create a directory to keep the manifests
```
mkdir manifests
```

2. re-run the deployment and redirect the output into manifest files for the deployment and service
```
kubectl run irvnet-hello-my-node --image=mycluster.icp:8500/default/hello-node:v1 --port=8080 -o yaml >  manifests/deployment.yaml
kubectl expose deployment irvnet-hello-my-node --type=NodePort -o yaml > manifests/service.yaml
```

3. clean up the environment
```
kubectl delete -f manifests/deployment.yaml
kubectl delete -f manifests/service.yaml
```

4. init helm project and add in our new definitions
```
helm create sample-chart
cp manifests/deployment.yaml sample-chart/templates/deployment.yaml
cp manifests/service.yaml sample-chart/templates/service.yaml
rm sample-chart/templates/ingress.yaml
```

5. install the cart from the exploded directory and review it
```
helm install -n sample-chart sample-chart
```

6. cleanup
```
helm delete sample-chart
```

Summary: The containerized process has been packaged as a chart and tested as an exploded directory

---

## Task 5: Uploading the chart to the ICP catalog

1. update values.yaml so the default values show correctly at deployment time

2. package the chart
```
helm package sample-charts
```

3. log into the cluster with bx (using admin/admin)
```
bx pr login -a https://{icp-cluster-ip}:8443  --skip-ssl-validation
```

4. load the helm chart into the repo
```
bx pr load-helm-chart --archive sample-chart-0.1.0.1.tgz
```

5. sync repository (or the details won't show)
