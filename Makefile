.DEFAULT_GOAL := create

init:
	terraform init

create: init
	terraform plan -out aro.plan 		                       \
		-var "cluster_name=aro-${USER}"                      \
		-var "pull_secret_path=~/Downloads/pull-secret.json" \
		-var "aro_version=4.10.40"

	terraform apply aro.plan

create-private: init
	terraform plan -out aro.plan 		                       \
		-var "cluster_name=aro-${USER}"                      \
		-var "restrict_egress_traffic=true"		               \
		-var "api_server_profile=Private"                    \
		-var "ingress_profile=Private"                       \
		-var "pull_secret_path=~/Downloads/pull-secret.json" \
		-var "aro_version=4.11.31"
	
	terraform apply aro.plan

create-private-noegress: init
	terraform plan -out aro.plan 		                       \
		-var "cluster_name=aro-${USER}"                      \
		-var "restrict_egress_traffic=false"		             \
		-var "api_server_profile=Private"                    \
		-var "ingress_profile=Private"                       \
		-var "pull_secret_path=~/Downloads/pull-secret.json" \
		-var "aro_version=4.11.31"

	terraform apply aro.plan

destroy:
	terraform destroy \
	-var "pull_secret_path=~/Downloads/pull-secret.json" 

destroy.force:
	terraform destroy \
	-var "pull_secret_path=~/Downloads/pull-secret.json" -auto-approve

delete: destroy

help:
	@echo make [create|destroy]
