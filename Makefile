.PHONY: fmt fmt-check init validate plan apply destroy

.DEFAULT_GOAL := validate

fmt:
	cd terraform && terraform fmt -recursive

fmt-check:
	cd terraform && terraform fmt -check -recursive

init:
	cd terraform && terraform init

validate: fmt-check
	cd terraform && terraform init -input=false -backend=false
	cd terraform && terraform validate

plan: init
	cd terraform && terraform plan

apply: init
	cd terraform && terraform apply

destroy: init
	cd terraform && terraform destroy
