DOTNET ?= dotnet
POWERSHELL ?= pwsh
WINDOWS_APP = Sources/Windows/App/PBScreenshot.App.csproj

.PHONY: windows-build windows-test windows-test-native windows-package windows-install windows-uninstall windows-test-install windows-help
windows-build: ## Cross-compile the Windows tray application
	$(DOTNET) build $(WINDOWS_APP) -c Release
windows-test: ## Run portable Windows settings tests on any host
	$(DOTNET) run --project Tests/Windows/Core/Core.Tests.csproj -c Release
windows-test-native: ## Test real capture, clipboard, hotkeys, startup on Windows
	$(DOTNET) run --project Tests/Windows/Native/Native.Tests.csproj -c Release
windows-package: ## Build a self-contained x64 installer (Windows, Inno Setup 6)
	$(POWERSHELL) -NoProfile -File scripts/windows/package.ps1
windows-install: ## Install the packaged app for this user (no admin)
	$(POWERSHELL) -NoProfile -File scripts/windows/install.ps1
windows-uninstall: ## Uninstall while preserving user settings
	$(POWERSHELL) -NoProfile -File scripts/windows/install.ps1 -Uninstall
windows-test-install: ## Exercise install/uninstall/reinstall in a disposable Windows CI VM
	$(POWERSHELL) -NoProfile -File scripts/windows/test-install.ps1
windows-help:
	@echo windows-build: Build the Windows application
	@echo windows-test: Run settings tests
	@echo windows-test-native: Test Windows desktop APIs
	@echo windows-package: Create a self-contained installer
	@echo windows-install: Install for the current user
	@echo windows-uninstall: Uninstall and keep preferences
	@echo windows-test-install: Test installation lifecycle in CI
