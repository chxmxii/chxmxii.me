.PHONY: clean
clean:
	@rm -rf public
	@rm -rf resources

.PHONY: run
run:
	@hugo server -D