.PHONY: clean
clean:
	@rm -rf public resources

.PHONY: run
run:
	@hugo server -D

.PHONY: commit
commit:
	@if [ -z "$$(git status --porcelain)" ]; then \
		echo "No changes to commit."; \
		exit 0; \
	fi; \
	if [ -z "$(m)" ]; then \
		exit 1; \
	fi; \
	scope=$${s:-general}; \
	git add .; \
	git commit -m "$$scope: $(m)"; \
	git push origin master

.PHONY: push
push:
	@make commit m="Update site" s="general"
