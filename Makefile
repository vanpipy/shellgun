PREFIX ?= /usr/local
BINPREFIX ?= "$(PREFIX)/bin"
COMPDIR ?= "$(PREFIX)/share"

SECURITY_CONF_DIR := scripts/SecurityConfigure
BUILD_SCRIPT := $(SECURITY_CONF_DIR)/build.sh
SRC_FILES := $(wildcard $(SECURITY_CONF_DIR)/src/*.sh)
OUT_DIR := lib
OUT_FILE := $(OUT_DIR)/security-configure

SPEC_DIR := scripts/SpeckitConfigure
SPEC_BUILD_SCRIPT := $(SPEC_DIR)/build.sh
SPEC_OUT_FILE := $(OUT_DIR)/speckit-configure

BASH_COMP_DIR := $(COMPDIR)/bash-completion/completions
ZSH_COMP_DIR := $(COMPDIR)/zsh/site-functions

default: install

.PHONY: security-configure
security-configure: $(OUT_FILE)

$(OUT_FILE): $(SRC_FILES) $(BUILD_SCRIPT) | $(OUT_DIR)
	@echo "[MAKE] Building security-configure"
	bash $(BUILD_SCRIPT)

.PHONY: speckit-configure
speckit-configure: $(SPEC_OUT_FILE)

$(SPEC_OUT_FILE): $(SPEC_BUILD_SCRIPT) $(wildcard $(SPEC_DIR)/src/*.sh) | $(OUT_DIR)
	@echo "[MAKE] Building speckit-configure"
	bash $(SPEC_BUILD_SCRIPT)

$(OUT_DIR):
	@mkdir -p $(OUT_DIR)

install: security-configure speckit-configure
	@echo "Install bins to $(BINPREFIX)"
	@mkdir -p $(BINPREFIX)
	@ls ./bin | grep "^git" | xargs -I {} cp ./bin/{} $(BINPREFIX)/{}
	@cp ./lib/security-configure $(BINPREFIX)/
	@cp $(SPEC_OUT_FILE) $(BINPREFIX)/speckit-configure
	@mkdir -p $(BASH_COMP_DIR) $(ZSH_COMP_DIR)
	@cp ./lib/security-configure.bash $(BASH_COMP_DIR)/security-configure
	@cp ./lib/_security-configure $(ZSH_COMP_DIR)/_
	@echo "Cleaning up build dir..."
	@rm -rf ./lib

uninstall:
	@echo "Uninstall..."
	@ls ./bin | grep "^git" | xargs -I {} rm "$(BINPREFIX)/{}"
	@rm -f "$(BINPREFIX)/security-configure"
	@rm -f "$(BINPREFIX)/speckit-configure"
	@rm -f "$(BASH_COMP_DIR)/security-configure"
	@rm -f "$(ZSH_COMP_DIR)/_security-configure"
	@echo
	@echo "Completed."

clean: clean-security-configure clean-speckit-configure
	@echo "Make clean..."
	@echo "Nothing done."

.PHONY: clean-speckit-configure
clean-speckit-configure:
	@rm -f $(SPEC_OUT_FILE)

.PHONY: clean-security-configure
clean-security-configure:
	@rm -rf lib/

.PHONY: test
test:
	@bash tests/linux-env-setup/setup_tmux.test.sh
