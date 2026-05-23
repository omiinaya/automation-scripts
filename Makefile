.PHONY: test

test:
	cd tests && pwsh -Command "Invoke-Pester"

lint:
	pwsh -Command "Invoke-ScriptAnalyzer -Path . -Recurse"

clean:
	rm -rf __pycache__
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
