.PHONY: test lint deploy-frontend tf-plan tf-apply zip

test:
	pytest tests/ -v --cov=src --cov-report=term-missing

lint:
	ruff check src/ tests/ --fix

deploy-frontend:
	aws s3 sync frontend/ s3://event-ticketing-prod-frontend-ui-12345/ --delete
	# Requires CLOUDFRONT_DIST_ID in env
	aws cloudfront create-invalidation --distribution-id $CLOUDFRONT_DIST_ID --paths "/*"

tf-plan:
	cd terraform && terraform plan

tf-apply:
	cd terraform && terraform apply

zip:
	mkdir -p dist
	for handler in register get_events get_registrations delete_registration create_event update_event delete_event authorizer; do \
		zip -j dist/$$handler.zip src/$$handler.py src/shared.py src/email_service.py; \
	done
