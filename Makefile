.DEFAULT_GOAL := help
.NOTPARALLEL:
include makefiles/windows.mk

ifeq ($(OS),Windows_NT)
.PHONY: help build test install uninstall
help: windows-help
build: windows-build
test: windows-test windows-test-native
install: windows-package windows-install
uninstall: windows-uninstall
else
.DEFAULT_GOAL := help

# Override for toolchain issues, e.g. SWIFT_FLAGS=--build-system=native.
SWIFT_FLAGS ?=
INSTALL_DIR ?= $(HOME)/Applications
# Ad-hoc signing is local and requires no Apple account or certificate.
LOCAL_SIGN_ID ?= -

# ============================================================================
# Configuration
# ============================================================================
NAME       = pbscreenshot
AGENT      = pbscreenshot-agent
APP_NAME   = pbscreenshot.app
BUNDLE_ID  = com.olshansky.pbscreenshot
REPO       = olshansk/pbscreenshot
TAP        = olshansk/homebrew-tap

VERSION   := $(shell awk -F'"' '/static let version/ {print $$2}' Sources/Core/Config/Version.swift)

BUILD_DIR    = .build
DIST_DIR     = dist
UNIVERSAL    = $(BUILD_DIR)/universal/release
APP          = $(DIST_DIR)/$(APP_NAME)
LOCAL_APP    = $(DIST_DIR)/local/$(APP_NAME)
DMG          = $(DIST_DIR)/$(NAME)-$(VERSION).dmg

# Resolved from the keychain rather than hardcoded — certificate common names
# contain surprises, and a stale literal fails with an opaque keychain error.
SIGN_ID    = $(shell security find-identity -v -p codesigning | awk -F'"' '/Developer ID Application/ {print $$2; exit}')
NOTARY_PROFILE ?= pbscreenshot-notary

# ============================================================================
# Colors & Symbols
# ============================================================================
GREEN  := \033[0;32m
YELLOW := \033[1;33m
RED    := \033[0;31m
CYAN   := \033[0;36m
BOLD   := \033[1m
RESET  := \033[0m

CHECK := ✓
CROSS := ✗

# ============================================================================
# Development
# ============================================================================
.PHONY: build test lint launch install install-clt uninstall kill _local-app

build: ## Build debug binaries
	@printf "$(CYAN)Building debug...$(RESET)\n"
	@swift build $(SWIFT_FLAGS)
	@printf "$(GREEN)$(CHECK) Built $(BUILD_DIR)/debug/$(NAME)$(RESET)\n"

test: ## Run the test suite
	@swift test $(SWIFT_FLAGS)

lint: ## Format sources with swift-format (no-op if unavailable)
	@command -v swift-format >/dev/null 2>&1 && \
		swift-format format --in-place --recursive Sources Tests && \
		printf "$(GREEN)$(CHECK) Formatted$(RESET)\n" || \
		printf "$(YELLOW)swift-format not installed — skipping. Install it with: brew install swift-format$(RESET)\n"

launch: install ## Build and launch locally; no Apple account or certificate required
	@open "$(INSTALL_DIR)/$(APP_NAME)"
	@printf "$(GREEN)$(CHECK) Launched — look for the camera icon in the menu bar$(RESET)\n"

_local-app: build
	@binaries=$$(swift build $(SWIFT_FLAGS) --show-bin-path) && \
		bash scripts/macos/assemble-app.sh "$$binaries" "$(LOCAL_APP)" "$(VERSION)"
	@codesign --force --timestamp=none --sign "$(LOCAL_SIGN_ID)" "$(LOCAL_APP)/Contents/MacOS/$(NAME)"
	@codesign --force --timestamp=none --sign "$(LOCAL_SIGN_ID)" "$(LOCAL_APP)/Contents/MacOS/$(AGENT)"
	@codesign --force --timestamp=none --sign "$(LOCAL_SIGN_ID)" "$(LOCAL_APP)"
	@codesign --verify --deep --strict "$(LOCAL_APP)"
	@if [ "$(LOCAL_SIGN_ID)" = "-" ]; then \
		printf "$(YELLOW)Local ad-hoc build: macOS may require Screen Recording approval again after rebuilding.$(RESET)\n"; \
	fi

install-clt: ## Build and install using the Command Line Tools fallback
	@bash scripts/macos/make-with-clt.sh install

install: _local-app ## Build and install locally without a developer certificate
	@mkdir -p "$(INSTALL_DIR)"
	@rm -rf "$(INSTALL_DIR)/.$(APP_NAME).new"
	@ditto "$(LOCAL_APP)" "$(INSTALL_DIR)/.$(APP_NAME).new"
	@codesign --verify --deep --strict "$(INSTALL_DIR)/.$(APP_NAME).new"
	@pkill -x $(AGENT) 2>/dev/null && sleep 1 || true
	@rm -rf "$(INSTALL_DIR)/$(APP_NAME)"
	@mv "$(INSTALL_DIR)/.$(APP_NAME).new" "$(INSTALL_DIR)/$(APP_NAME)"
	@printf "$(GREEN)$(CHECK) Installed to $(INSTALL_DIR)/$(APP_NAME)$(RESET)\n"

uninstall: kill ## Remove the installed app, preserving preferences and permissions
	@rm -rf "$(INSTALL_DIR)/$(APP_NAME)"
	@printf "$(GREEN)$(CHECK) Removed $(INSTALL_DIR)/$(APP_NAME); preferences preserved$(RESET)\n"

kill: ## Quit the running menu bar agent
	@pkill -x $(AGENT) 2>/dev/null && \
		printf "$(GREEN)$(CHECK) Agent stopped$(RESET)\n" || \
		printf "$(YELLOW)Agent not running$(RESET)\n"

# ============================================================================
# Packaging
# ============================================================================
.PHONY: build-release app sign dmg notarize release cask

build-release: ## Build universal (arm64 + x86_64) release binaries
	@printf "$(CYAN)Building universal release...$(RESET)\n"
	@bash scripts/macos/build-release.sh $(SWIFT_FLAGS)
	@printf "$(GREEN)$(CHECK) Built $(UNIVERSAL)$(RESET)\n"

app: build-release ## Assemble pbscreenshot.app (agent + CLI in one bundle)
	@printf "$(CYAN)Assembling $(APP_NAME)...$(RESET)\n"
	@bash scripts/macos/assemble-app.sh "$(UNIVERSAL)" "$(APP)" "$(VERSION)"
	@printf "$(GREEN)$(CHECK) $(APP) (v$(VERSION))$(RESET)\n"

sign: ## Code sign the bundle with hardened runtime (inner binaries first)
	@test -n "$(SIGN_ID)" || { printf "$(RED)$(CROSS) No Developer ID Application identity in keychain$(RESET)\n"; exit 1; }
	@printf "$(CYAN)Signing as: $(SIGN_ID)$(RESET)\n"
	@codesign --force --options runtime --timestamp --sign "$(SIGN_ID)" "$(APP)/Contents/MacOS/$(NAME)"
	@codesign --force --options runtime --timestamp --sign "$(SIGN_ID)" "$(APP)/Contents/MacOS/$(AGENT)"
	@codesign --force --options runtime --timestamp --sign "$(SIGN_ID)" "$(APP)"
	@codesign --verify --deep --strict --verbose=2 "$(APP)"
	@printf "$(GREEN)$(CHECK) Signed$(RESET)\n"

dmg: ## Build the distributable DMG
	@test -d "$(APP)" || { printf "$(RED)$(CROSS) No bundle at $(APP). Run: make app$(RESET)\n"; exit 1; }
	@printf "$(CYAN)Creating $(DMG)...$(RESET)\n"
	@rm -f "$(DMG)"
	@if command -v create-dmg >/dev/null 2>&1; then \
		create-dmg --volname "$(NAME)" --window-size 520 340 \
			--icon "$(APP_NAME)" 130 150 --app-drop-link 390 150 \
			--no-internet-enable "$(DMG)" "$(APP)" >/dev/null; \
	else \
		printf "$(YELLOW)create-dmg not installed — falling back to hdiutil$(RESET)\n"; \
		hdiutil create -volname "$(NAME)" -srcfolder "$(APP)" -ov -format UDZO "$(DMG)" >/dev/null; \
	fi
	@printf "$(GREEN)$(CHECK) $(DMG)$(RESET)\n"

notarize: ## Submit the DMG to Apple and staple the ticket
	@test -f "$(DMG)" || { printf "$(RED)$(CROSS) No DMG at $(DMG). Run: make dmg$(RESET)\n"; exit 1; }
	@printf "$(CYAN)Notarizing (this takes a few minutes)...$(RESET)\n"
	@xcrun notarytool submit "$(DMG)" --keychain-profile "$(NOTARY_PROFILE)" --wait
	@xcrun stapler staple "$(DMG)"
	@xcrun stapler validate "$(DMG)"
	@printf "$(GREEN)$(CHECK) Notarized and stapled$(RESET)\n"

release: app sign dmg notarize cask ## Full pipeline: build, sign, DMG, notarize, print cask
	@printf "$(GREEN)$(CHECK) Release $(VERSION) ready: $(DMG)$(RESET)\n"

cask: ## Print the Homebrew cask block for the current DMG
	@test -f "$(DMG)" || { printf "$(RED)$(CROSS) No DMG at $(DMG). Run: make dmg$(RESET)\n"; exit 1; }
	@printf "\n$(BOLD)=== Casks/$(NAME).rb ===$(RESET)\n"
	@sed -e 's/@VERSION@/$(VERSION)/g' \
	     -e "s/@SHA256@/$$(shasum -a 256 '$(DMG)' | cut -d' ' -f1)/g" \
	     packaging/$(NAME).rb
	@printf "\n$(CYAN)Copy into the $(TAP) repo, then: brew install --cask $(TAP)/$(NAME)$(RESET)\n"

# ============================================================================
# Diagnostics
# ============================================================================
.PHONY: doctor info

doctor: ## Check the toolchain needed to cut a release
	@printf "$(BOLD)=== Release readiness ===$(RESET)\n"
	@printf "$(CYAN)%-22s$(RESET) " "swift"; swift --version 2>/dev/null | head -1 || printf "$(RED)$(CROSS) missing$(RESET)\n"
	@printf "$(CYAN)%-22s$(RESET) " "signing identity"; \
		if [ -n "$(SIGN_ID)" ]; then printf "$(GREEN)$(CHECK) $(SIGN_ID)$(RESET)\n"; \
		else printf "$(RED)$(CROSS) no Developer ID Application cert$(RESET)\n"; fi
	@printf "$(CYAN)%-22s$(RESET) " "notary profile"; \
		if xcrun notarytool history --keychain-profile "$(NOTARY_PROFILE)" >/dev/null 2>&1; then \
			printf "$(GREEN)$(CHECK) $(NOTARY_PROFILE)$(RESET)\n"; \
		else \
			printf "$(RED)$(CROSS) missing$(RESET) — run: xcrun notarytool store-credentials $(NOTARY_PROFILE)\n"; fi
	@printf "$(CYAN)%-22s$(RESET) " "create-dmg"; \
		command -v create-dmg >/dev/null 2>&1 && printf "$(GREEN)$(CHECK) installed$(RESET)\n" || \
		printf "$(YELLOW)missing (hdiutil fallback)$(RESET) — install it with: brew install create-dmg\n"

info: ## Show build product info
	@printf "$(BOLD)=== $(NAME) $(VERSION) ===$(RESET)\n"
	@printf "$(CYAN)%-22s$(RESET) %s\n" "Bundle ID:" "$(BUNDLE_ID)"
	@if [ -d "$(APP)" ]; then \
		printf "$(CYAN)%-22s$(RESET) %s\n" "App:" "$(APP)"; \
		printf "$(CYAN)%-22s$(RESET) " "Architectures:"; lipo -archs "$(APP)/Contents/MacOS/$(NAME)" 2>/dev/null || echo "?"; \
		printf "$(CYAN)%-22s$(RESET) " "Signature:"; codesign -dv "$(APP)" 2>&1 | grep -i "^Authority" | head -1 || printf "$(YELLOW)unsigned$(RESET)\n"; \
		printf "$(CYAN)%-22s$(RESET) %s\n" "Size:" "$$(du -sh "$(APP)" | cut -f1)"; \
	else \
		printf "$(YELLOW)No bundle yet. Run: make app$(RESET)\n"; \
	fi

# ============================================================================
# Maintenance
# ============================================================================
.PHONY: clean

clean: ## Remove build and dist artifacts
	@rm -rf $(BUILD_DIR) $(DIST_DIR)
	@printf "$(GREEN)$(CHECK) Cleaned$(RESET)\n"

# ============================================================================
# Help
# ============================================================================
.PHONY: help

help: windows-help ## Show available commands
	@printf "\n"
	@printf "$(BOLD)$(CYAN)╔═══════════════════════════════╗$(RESET)\n"
	@printf "$(BOLD)$(CYAN)║        pbscreenshot           ║$(RESET)\n"
	@printf "$(BOLD)$(CYAN)╚═══════════════════════════════╝$(RESET)\n\n"
	@printf "$(BOLD)=== 🔧 Development ===$(RESET)\n"
	@printf "$(CYAN)%-18s$(RESET) %s\n" "build" "Build debug binaries"
	@printf "$(CYAN)%-18s$(RESET) %s\n" "test" "Run the test suite"
	@printf "$(CYAN)%-18s$(RESET) %s\n" "lint" "Format sources with swift-format"
	@printf "$(CYAN)%-18s$(RESET) %s\n" "launch" "Build, install, and launch locally"
	@printf "$(CYAN)%-18s$(RESET) %s\n" "install" "Build and install locally; no developer certificate"
	@printf "$(CYAN)%-18s$(RESET) %s\n" "install-clt" "Build and install with the Command Line Tools fallback"
	@printf "$(CYAN)%-18s$(RESET) %s\n" "uninstall" "Remove installed app; preserve preferences"
	@printf "$(CYAN)%-18s$(RESET) %s\n" "kill" "Quit the running agent"
	@printf "\n"
	@printf "$(BOLD)=== 📦 Packaging ===$(RESET)\n"
	@printf "$(CYAN)%-18s$(RESET) %s\n" "build-release" "Build universal release binaries"
	@printf "$(CYAN)%-18s$(RESET) %s\n" "app" "Assemble pbscreenshot.app"
	@printf "$(CYAN)%-18s$(RESET) %s\n" "sign" "Code sign with hardened runtime"
	@printf "$(CYAN)%-18s$(RESET) %s\n" "dmg" "Build the distributable DMG"
	@printf "$(CYAN)%-18s$(RESET) %s\n" "notarize" "Submit to Apple and staple"
	@printf "$(CYAN)%-18s$(RESET) %s\n" "release" "Full pipeline end to end"
	@printf "$(CYAN)%-18s$(RESET) %s\n" "cask" "Print the Homebrew cask block"
	@printf "\n"
	@printf "$(BOLD)=== 🩺 Diagnostics ===$(RESET)\n"
	@printf "$(CYAN)%-18s$(RESET) %s\n" "doctor" "Check release toolchain readiness"
	@printf "$(CYAN)%-18s$(RESET) %s\n" "info" "Show build product info"
	@printf "\n"
	@printf "$(BOLD)=== 🧹 Maintenance ===$(RESET)\n"
	@printf "$(CYAN)%-18s$(RESET) %s\n" "clean" "Remove build and dist artifacts"
	@printf "\n"

# ============================================================================
# Error Handling
# ============================================================================
%:
	@printf "$(RED)$(CROSS) Unknown target '$@'$(RESET)\n"
	@printf "   Run $(CYAN)make help$(RESET) to see available targets\n"
	@exit 1

endif
