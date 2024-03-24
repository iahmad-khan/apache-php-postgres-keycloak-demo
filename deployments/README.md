# APACHE PHP KEYCLOAK POSTGRES

This is a depoloyment of apache php app that uses postgres as backend, and keyload for SSO using OIDC
Apache and keycloak are sharing the same Postgres instance


# How to set this up, run

/etc/hosts file entries

```

127.0.0.1 webserver

127.0.0.1 keycloak

```


then run:


```

MacBook-Pro:deployments Apple$ docker-compose up -d
[+] Running 4/4
 ✔ Network deployments_default       Created                                                                                                                      
0.1s 
 ✔ Container deployments-postgres-1  Started                                                                                                                      
0.1s 
 ✔ Container PHP-webServer           Started                                                                                                                      
0.1s 
 ✔ Container keycloak                Started                                                                                                                      
0.1s 


MacBook-Pro:deployments Apple$ docker ps

CONTAINER ID   IMAGE                     COMMAND                  CREATED         STATUS         PORTS                              NAMES
0dc00193a1b7   ijazahmad/apache-php:v1   "docker-php-entrypoi…"   4 seconds ago   Up 3 seconds   0.0.0.0:8000->80/tcp               PHP-webServer
9a06b84a6b1c   ijazahmad/keycloak:v1     "/opt/keycloak/bin/k…"   4 seconds ago   Up 3 seconds   0.0.0.0:8080->8080/tcp, 8443/tcp   keycloak
81c7366d7228   ijazahmad/postgres16:v1   "docker-entrypoint.s…"   4 seconds ago   Up 3 seconds   0.0.0.0:5432->5432/tcp             deployments-postgres-1

```



Access apche page https://webserver:8000 will redirect to keyloak, after user authenticates, it will access apache php page




# Setup details

- the apache conf file 000-default.conf is copied from current dir to container during docker-compose build/up
- deploy keycloak, apache-php and postgres using docker compose up ( docker-compose.yaml.orig file )
- run apache-config.sh script ( kcadm commands ) inside keycloak container to set things up for OIDC config for apache to use
- commit all the containers as new docker images and push them to dockrhub
- update docker-compose.yml to use the pre-configured images
- use docker-compose up -d , to run the pre-configured setup, this time no config needed, everything just works


