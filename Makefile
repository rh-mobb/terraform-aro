.DEFAULT_GOAL := create

create:
	terraform plan -out aro.plan \
		-var "cluster_name=aro-${USER}" \

	terraform apply aro.plan

destroy:
	terraform destroy -force

help:
	@echo make [create|destroy]
