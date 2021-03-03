#!/bin/bash

MISC_PATH="$(dirname "$0")"

# Colored text
RC='\033[1;31m' # Red
NC='\033[0m'    # No Color
WC='\033[1;34m' # blue

ARGO_VERSION="v1.8.3"

# Install Argo-stack
function install_argo() {
  echo "Installing Argo version ${ARGO_VERSION}"
  kubectl apply -n argocd -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGO_VERSION}/manifests/install.yaml"

  # Getting first password
  ARGO_INIT_PASSWORD=$(kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2)
  echo -e "\n${WC}If there is no SSO configured please don't forget to change the argocd password${NC}"
  echo -e "${WC}First time password is:${NC} ${ARGO_INIT_PASSWORD}"
}

function add_argo_ssh_key() {
  echo "downloading Nexite ssh key for argocd"
  kubectl apply -f external-secrets.yml
}



echo -e "Please choose the deploy env (please add new if needed)?"
PS3="Choice: "
options=("staging" "production" "qa" "abort")
select opt in "${options[@]}"; do
  case ${opt} in
  "staging")
    DEPLOY_ENV="staging"
  ;;
  "production")
    DEPLOY_ENV="production"
  ;;
  "qa")
    DEPLOY_ENV="qa"
  ;;
  "abort")
    echo -e "${RC}Exiting${NC}"
    exit 0
  ;;
  esac
  break
done

GET_CURRENT_CONTEXT=$(kubectl config current-context)

echo -e "\nChecking if running on the right cluster...\n"
if echo "${GET_CURRENT_CONTEXT}" | grep ${DEPLOY_ENV}; then
  echo "You are in the right cluster moving on with the depoy"
else
  echo -e "${RC}Please change to the right kubernetes cluster\nExiting...${NC}"
  exit 1
fi

kubectl create namespace argocd 2>/dev/null || echo "namespaces 'argocd' already exists"
add_argo_ssh_key
install_argo
kubectl apply -f "${MISC_PATH}/projects.yml"
kubectl apply -f "${MISC_PATH}/repositories.yml"
kubectl apply -f "${MISC_PATH}/../app-of-apps/${DEPLOY_ENV}.yaml"
