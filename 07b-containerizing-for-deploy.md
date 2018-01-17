
## Containerizing a java application process for deployment

**In this section**, you will learn how to package a java application running on WAS Liberty in a docker container to run on the IBM Cloud Private (ICP) platform. In addition, the applications image will be packaged in a helm chart for deployment from the ICP catalog.

Development processes such as these are typically sped up with enhancements such as an automated DevOps process, however it's helpful to have exposure to how some of the underlying parts of the process work. To provide a clear view of the task at hand, lets assume that our DevOps process as assembled the application components for us to package.

## Task 1: Package WAS Liberty application as a Docker image

In this section we'll package a java application in a docker image. We'll  test  the image locally and push the results to the ICP image repository to run in the cluster.

1. create a file named 'Dockerfile' to package our application components into a single image and enter the following code

```
FROM websphere-liberty:kernel
COPY server.xml  /config/
COPY oas3-airlines.war /config/apps/
COPY LibertyDropinApps/* /config/dropins
RUN installUtility install --acceptLicense defaultServer
```

3. Build the Docker image
```
$ docker build -t libertyair:v1.0 .
```

4. Run the image and test it locally

```
$ docker run --rm --name airline-app -i -p 9080:9080 libertyair
```

  For a quick test of the container running locally on your machine, In your browser, access any of the following links:

  - [http://localhost:9080/api/docs/](http://localhost:9080/api/docs/)
  - [http://localhost:9080/api/explorer/](http://localhost:9080/api/explorer/)
  - [http://localhost:9080/myServletWAR/](http://localhost:9080/myServletWAR/)
  - [http://localhost:9080/airlines/](http://localhost:9080/airlines/)


5. Stop the locally running container

```  
$ docker stop airline-app
```


---


## Task 2: Deploy from the ICP cluster image repository

1. login to the cluster repo (username: admin / pwd: admin)

```
$ docker login mycluster.icp:8500
```


2. Tag the image for pushing to the cluster's image repo

```
$ docker tag libertyair:v1 mycluster.icp:8500/default/libertyair:v1

$ docker push mycluster.icp:8500/default/libertyair:v1
```


3. Edit the image to change the scope from namespace to global so anyone can run it

```
$ kubectl edit image libertyair -n default

```

4. Run the image from the command line and see the available deployment in the dashboard

```
$ kubectl run irvnet-air --image=mycluster.icp:8500/default/libertyair:v1 --port=8080
```


5. Expose the pod to the internet by creating a service

```
$ kubectl expose deployment irvnet-air --type=LoadBalancer
```


6. find the new service and get the new port

```
$ kubectl get services

```


Summary: The image with the node process has been tested on the ICP cluster showing several capabilities that deployments offer.

---

## Task 3:  Push an updated image to the ICP image repository

1. tag the image and push to the cluster's image repo

```
$ docker tag libertyair:v2 mycluster.icp:8500/default/libertyair:v2

$ docker push mycluster.icp:8500/default/libertyair:v2

```

2. deploy the updated version to the cluster
```
$ kubectl set image deployment/irvnet-air  irvnet-air=mycluster.icp:8500/default/libertyair:v2

```

3. curl the open port to see the updated message


---

## Task 4: Deploying the sample process as a helm chart

1. create a directory to keep the manifests
```
$ mkdir manifests

```

2. re-run the deployment and redirect the output into manifest files for the deployment and service
```
$ kubectl run irvnet-air --image=mycluster.icp:8500/default/hello-node:v1 --port=8080 -o yaml >  manifests/deployment.yaml

$ kubectl expose deployment irvnet-air --type=NodePort -o yaml > manifests/service.yaml
```

3. clean up the environment
```
$ kubectl delete -f manifests/deployment.yaml

$ kubectl delete -f manifests/service.yaml
```

4. init helm project and add in our new definitions
```
$ helm create liberty-air-chart

$ cp manifests/deployment.yaml sample-chart/templates/deployment.yaml

$ cp manifests/service.yaml sample-chart/templates/service.yaml

$ rm sample-chart/templates/ingress.yaml

```

5. install the cart from the exploded directory and review it
```
$ helm install -n liberty-air-chart liberty-air-chart

```

6. cleanup
```
$ helm delete liberty-air-chart

```

Summary: The containerized process has been packaged as a chart and tested as an exploded directory

---

## Task 5: Uploading the chart to the ICP catalog

1. update values.yaml so the default values show correctly at deployment time

2. package the chart

```
$ helm package sample-charts
```

3. log into the cluster with bx (using admin/admin)

```
$ bx pr login -a https://{icp-cluster-ip}:8443  --skip-ssl-validation
```

4. load the helm chart into the repo

```
$ bx pr load-helm-chart --archive liberty-air-chart-0.1.0.1.tgz
```

5. sync repository (or the details won't show)
