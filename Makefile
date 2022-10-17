.DEFAULT_GOAL := create

create:
	terraform plan -out aro.plan \
		-var "cluster_name=aro-${USER}" \

	terraform apply aro.plan

destroy:
	terraform destroy

destroy.force:
	terraform destroy -auto-approve

delete: destroy

help:
	@echo make [create|destroy]
