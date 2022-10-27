.DEFAULT_GOAL := create

init:
	terraform init

create: init
	terraform plan -out aro.plan 		\
		-var "cluster_name=aro-${USER}" \

	terraform apply aro.plan

create-private: init
	terraform plan -out aro.plan 		\
		-var "cluster_name=aro-${USER}" \
		-var "egress_lockdown=true"		\
		-var "aro_private=true"

	terraform apply aro.plan


destroy:
	terraform destroy

destroy.force:
	terraform destroy -auto-approve

delete: destroy

help:
	@echo make [create|destroy]
