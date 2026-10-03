# 使い方: make help
ENV        ?= local
NAME       ?= webapp
LANG_      ?= python
TF         := terraform -chdir=infra/envs/$(ENV)
TFVARS     := -var name=$(NAME) -var lambda_lang=$(LANG_)
MS         := http://localhost:4566
LOCAL_AWS  := AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=ap-northeast-1 aws --endpoint-url=$(MS)

.PHONY: help up down init build-go apply destroy image smoke db-check out

help:
	@echo "make up                 MiniStack 起動"
	@echo "make apply              local に全構成を作成（LANG_=python|node|go）"
	@echo "make smoke              API(Lambda) と ALB(ECS) に疎通確認"
	@echo "make db-check           RDS(PostgreSQL) に接続確認"
	@echo "make destroy            local の構成を削除"
	@echo "make apply ENV=prod     会社の AWS に反映（要 profile=company）"

up:
	docker compose up -d
	@until curl -sf $(MS)/_ministack/health >/dev/null; do sleep 1; done; echo "MiniStack ready"

down:
	docker compose down

init:
	$(TF) init -upgrade

build-go:
	cd apps/lambda-go && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -tags lambda.norpc -o dist/bootstrap .

# ECR を先に作り → イメージを build(/push) → 残りを作成
apply: init $(if $(filter go,$(LANG_)),build-go)
	$(TF) apply -auto-approve $(TFVARS) -target=module.app.module.container[0].aws_ecr_repository.app
	$(MAKE) image ENV=$(ENV)
	$(TF) apply -auto-approve $(TFVARS)

image:
	$(eval REPO := $(shell $(TF) state show -no-color 'module.app.module.container[0].aws_ecr_repository.app' | awk -F'"' '/repository_url/{print $$2}'))
	docker build -t $(REPO):latest apps/container
ifeq ($(ENV),prod)
	aws ecr get-login-password --profile company --region ap-northeast-1 | docker login --username AWS --password-stdin $(firstword $(subst /, ,$(REPO)))
	docker push $(REPO):latest
endif

destroy:
	$(TF) destroy -auto-approve $(TFVARS)

out:
	@$(TF) output -json app | jq

smoke:
	$(eval API := $(shell $(TF) output -json app | jq -r .api_id))
	$(eval ALB := $(shell $(TF) output -json app | jq -r .alb_name))
	@echo "--- API Gateway -> Lambda"; curl -sf $(MS)/_aws/execute-api/$(API)/hello; echo
	@echo "--- ALB -> ECS";            curl -sf $(MS)/_alb/$(ALB)/hello; echo

db-check:
	$(eval SECRET := $(shell $(LOCAL_AWS) secretsmanager get-secret-value --secret-id $(NAME)/db --query SecretString --output text))
	@docker run --rm --network host -e PGPASSWORD=$$(echo '$(SECRET)' | jq -r .password) postgres:16-alpine \
	  psql -h $$(echo '$(SECRET)' | jq -r .host) -p $$(echo '$(SECRET)' | jq -r .port) \
	       -U $$(echo '$(SECRET)' | jq -r .username) -d $$(echo '$(SECRET)' | jq -r .dbname) -c 'select version();'
