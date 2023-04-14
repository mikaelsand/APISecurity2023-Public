# APISecurity2023

This repo contains everything to get demos running.
The demos are connected to my talk on Top 10 things to secure your APIs.

## Parts

The demo contains XXX parts.

1. An APIm instance (not in repo)
2. A Private Link connected to the APIm instance (not in repo)
3. An Application Gateway
4. A Web Application Firewall (connected to the Application Gateway)
5. A backend function calling APIs at Trafikverket.se
6. Four versions of the API Trains, all calling the backend Function. Using different levels of security.
7. A "secured" function, using built in Azure authorization to allow calls.

## Code

### Bicep

Contains all the bicep files needed to deploy the solution.
Note the two versions of the Functon setup, one `common` and one `secure`. The `common` one is called from V1 of the API. All others use the `secure`.

### MyAPI

Contains all the APIm configuration to create the API that calls the backend function.
The API calls the backend function uses an appkey as part of the authentication.

The shared folder contains settings valid for all versions.

### Trafikverket API

A c# Azure Function that calls the Trafikverket API.
Please be nice, my coding skillz are not l33t.
