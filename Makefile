.PHONY: test lint test-unit test-integration tf-fmt tf-validate tf-plan tf-apply deploy-frontend zip

ENV ?= dev
TF_DIR = infrastructure/environments/$(ENV)

test: test-unit

test-unit:
	pytest tests/ -v -m "not integration" --cov=backend --cov-report=term-missing

test-integration:
	pytest tests/integration -v -m integration

lint:
	ruff check backend/ tests/

tf-fmt:
	terraform fmt -recursive infrastructure/

tf-validate:
	cd $(TF_DIR) && terraform validate

tf-plan:
	cd $(TF_DIR) && terraform plan

tf-apply:
	cd $(TF_DIR) && terraform apply

deploy-frontend:
	@test -n "$(CLOUDFRONT_DIST_ID)" || (echo "CLOUDFRONT_DIST_ID is required" && exit 1)
	@test -n "$(API_BASE_URL)" || (echo "API_BASE_URL is required" && exit 1)
	@tmpdir=$$(mktemp -d) && \
	  cp -a frontend/. "$$tmpdir/" && \
	  sed -i "s|__API_BASE_URL__|$(API_BASE_URL)|g" "$$tmpdir/index.html" && \
	  aws s3 sync "$$tmpdir/" s3://event-ticketing-$(ENV)-frontend-ui-12345/ --delete && \
	  rm -rf "$$tmpdir"
	aws cloudfront create-invalidation --distribution-id $(CLOUDFRONT_DIST_ID) --paths "/*"

zip:
	mkdir -p dist
	cd backend && zip -r ../dist/backend.zip . -x "*__pycache__*"
