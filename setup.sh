#!/bin/sh
# ----------------------- install brew in goinfre -----------------------

export MACHINE_STORAGE_PATH="/goinfre/$USER/.docker"
export MINIKUBE_HOME="/goinfre/$USER/.minikube"


if ! command -v brew &> /dev/null
then
  export HOME_BREW="/goinfre/$USER"
  rm -rf $HOME/.brew && rm -rf $HOME_BREW/.brew && git clone --depth=1 https://github.com/Homebrew/brew $HOME_BREW/.brew && export PATH=$HOME_BREW/.brew/bin:$PATH && brew update && echo "export PATH=$HOME_BREW/.brew/bin:$PATH" >> ~/.zshrc && echo "export MINIKUBE_HOME=\"/goinfre/$USER/.minikube\"" >> ~/.zshrc  && echo export "MACHINE_STORAGE_PATH=\"/goinfre/$USER/.docker\"" >> ~/.zshrc
	echo	"export HOME_BREW=\"/goinfre/$USER\""	>> ~/.zshrc
	echo	"export PATH=$HOME_BREW/.brew/bin:$PATH"
	echo	"export MACHINE_STORAGE_PATH=\"/goinfre/$USER/.docker\""	>> ~/.zshrc
	echo	"export MINIKUBE_HOME=\"/goinfre/$USER/.minikube\""	>> ~/.zshrc
	echo	"export MACHINE_STORAGE_PATH=\"/goinfre/$USER/.docker\""	>> ~/.zshrc

fi

# ----------------------- install kubectl -----------------------

if ! command -v kubectl &> /dev/null
then
	brew install kubectl
fi

# -----------------------  install minikube -----------------------

if ! command -v minikube &> /dev/null
then
	brew install minikube
	minikube addons enable dashboard
fi

# ----------------------- starting minikube  ----------------------- 

if ! command minikube status | grep Running &>/dev/null
then
	minikube start --extra-config=apiserver.service-node-port-range=1-65535
	set __SERVICES_IP__=$(minikube ip)
fi


# ----------------------- building images -----------------------

kubectl config use-context minikube
eval $(minikube docker-env)
	docker build -t mysql:ael-ghem ./srcs/Mysql/
	docker build -t phpmyadmin:ael-ghem ./srcs/phpMyAdmin
	docker build -t nginx:ael-ghem ./srcs/nginx/

# ----------------------- creating deployements and services ----------------------- 

	kubectl apply -f ./srcs/nginx.yaml
	kubectl apply -f ./srcs/mysql.yaml
	kubectl apply -f ./srcs/phpmyadmin.yaml

#                This will deploy MetalLB to cluste
if ! command kubectl get ClusterRole | grep metallb &> /dev/null
then
	kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/namespace.yaml
	kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/metallb.yaml
	kubectl create -f ./srcs/metalLB.yaml
		# On first install only
	if ! command kubectl get secret -A | grep metallb | grep memberlist &> /dev/null
	then
		kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
	fi
fi
