# Infrastructure

the terraform code inside the infrastructure directory creates the required infrastructure resources
 
 - VMs ( bastion and app server )
 - Networking/Security groups/firewalling
 - SSHD config to disable root  login
 - Docker runtime and docker-compose on app srver
 - DNS hosted zone for the domain ( that we dont have registered yet )
 - CERTBot installation and certs creations etc


Related commands

```

cd infrastructre

tfevn install 1.6.6
tfevn use 1.6.6

terraform init
terraform validate

terraform plan
terraform apply


```

# Deployments

 - the deployments directory
 - the docker and docker-compose files, along with keycloak script ( apache-config.sh ), and apache conf file 
 - configures everything required for this task, deployment dir contents need to be run on the app server ( keycloak, apache-php, and Postgres )


docker-compose has been tested locally and it works as required by the task with exception of SSL/TLS becuase we dont have a valid domain for letsencrypt
to work with.


If we register the domain that is coded inside terraform ( ijazxample.fun ), and then point the domain to AWS route53 dns  servers, certbot/letsenrypt should 
work and then we can use those certs to configure keycloak and Apache to run on HTTPS


To test the setup/deployment locally, clone the repo and cd into deployment dir and then run  ( you must have docker and docker-compose on your machine )



```

docker-compose up -d 


```

and then access apache-php on http://webserver:8000, it should redirect to keycloak and ask for


```

user:  apache
password: password.

```


once authentication is done, it should display the Apache php page with the message, "connected to postgres successfully" 



I have uploaded screenshots from my local depoloyement



Terraform code has been tested on AWS and it works, just the missing piece is domain registration with some service like godady


