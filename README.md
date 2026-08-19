# rhas-starter

A starter project for building RHIVOS/AutoSD images with a simple test application.

## TLDR

Build a simple test application, create an RPM from it and install the RPM during the AutoSD build. Once the OS image has been built, launch it as a "virtual device" and validate that it is working correctly.

TBD: Explain a bit more of the what and how. Keept it simple and brief, this is the TLDR.

## Setup

### OpenShift DevSpaces preparation

TBD: Describe the setup process, in broad strokes:
- create a user in RHAS by registering with keycloak
- ask an cluster admin to create a NAMESPACE before launching OpenShift DevSpaces: `scripts/namespace.sh <user>`
- as the <user>, log into the OpeShift web console and launch DevSpaces
- configure DevSpaces preferences:
  - gitconfig: git username & email
  - Personal Access Token:
    - name: "git-pac"
    - token: your GitHub PAT with sufficient rights to create webhooks and pull/push to the repo
- create a new DevSpace workspace from `https://github.com/rhadp-examples/rhas-starter`

### OpenShift DevSpaces workspace setup

TBD: Describe how to configure the workspace, in broad strokes:
- First, get your OpenShift login token from the OpenShift Web console ("Copy login command" -> Display token -> copy the token)
- After it launches, open the shell:
  - paste the login token, this completes your openshift setup
  - login to RHAS/Jumpstarter: run command `jmp-login` in the shell, follow the link to Keykloak and login/confirm
  - create the OpenShift Piplines-as-code setup: run script `pac-setup` 


  