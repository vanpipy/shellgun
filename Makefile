PREFIX ?= /usr/local
BINPREFIX ?= "$(PREFIX)/bin"
COMPDIR ?= "$(PREFIX)/share"

SECURITY_CONF_DIR := scripts/SecurityConfigure
BUILD_SCRIPT := $(SECURITY_CONF_DIR)/build.sh
SRC_FILES := $(wildcard $(SECURITY_CONF_DIR)/src/*.sh)
OUT_DIR := lib
OUT_FILE := $(OUT_DIR)/security-configure

BASH_COMP_DIR := $(COMPDIR)/bash-completion/completions
ZSH_COMP_DIR := $(COMPDIR)/zsh/site-functions

default: install

.PHONY: security-configure
security-configure: $(OUT_FILE)

$(OUT_FILE): $(SRC_FILES) $(BUILD_SCRIPT) | $(OUT_DIR)
	@echo "[MAKE] Building security-configure"
	bash $(BUILD_SCRIPT)

$(OUT_DIR):
	@mkdir -p $(OUT_DIR)

install: security-configure
	@echo "Install bins to $(BINPREFIX)"
	@mkdir -p $(BINPREFIX)
	@ls ./bin | grep "^git" | xargs -I {} cp ./bin/{} $(BINPREFIX)/{}
	@cp ./lib/security-configure $(BINPREFIX)/
	@mkdir -p $(BASH_COMP_DIR) $(ZSH_COMP_DIR)
	@cp ./lib/security-configure.bash $(BASH_COMP_DIR)/security-configure
	@cp ./lib/_security-configure $(ZSH_COMP_DIR)/_
	@echo "Cleaning up build dir..."
	@rm -rf ./lib

uninstall:
	@echo "Uninstall..."
	@ls ./bin | grep "^git" | xargs -I {} rm "$(BINPREFIX)/{}"
	@rm -f "$(BINPREFIX)/security-configure"
	@rm -f "$(BASH_COMP_DIR)/security-configure"
	@rm -f "$(ZSH_COMP_DIR)/_security-configure"
	@echo
	@echo "Completed."

clean: clean-security-configure
	@echo "Make clean..."
	@echo "Nothing done."

.PHONY: clean-security-configure
clean-security-configure:
	@rm -rf lib/
