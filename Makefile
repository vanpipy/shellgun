PREFIX ?= /usr/local
BINPREFIX ?= "$(PREFIX)/bin"

SECURITY_CONF_DIR := scripts/SecurityConfigure
BUILD_SCRIPT := $(SECURITY_CONF_DIR)/build.sh
SRC_FILES := $(wildcard $(SECURITY_CONF_DIR)/src/*.sh)
OUT_FILE := lib/security-configure.sh

default: install

.PHONY: security-configure
security-configure: $(OUT_FILE)

$(OUT_FILE): $(SRC_FILES) $(BUILD_SCRIPT) | lib
	@echo "[MAKE] Building security-configure"
	bash $(BUILD_SCRIPT)

lib:
	@mkdir -p lib

install: security-configure
	@echo "Install bins to $(BINPREFIX)"
	@ls ./bin | grep "^git" | xargs -I {} cp ./bin/{} $(BINPREFIX)/{}
	@cp ./lib/* $(BINPREFIX)/

uninstall:
	@echo "Uninstall..."
	@ls ./bin | grep "^git" | xargs -I {} rm "$(BINPREFIX)/{}"
	@rm -f "$(BINPREFIX)/security-configure" "$(BINPREFIX)/security-configure.sh"
	@echo
	@echo "Completed."

clean: clean-security-configure
	@echo "Make clean..."
	@echo "Nothing done."

.PHONY: clean-security-configure
clean-security-configure:
	@rm -f ./lib/security-configure ./lib/security-configure.sh
	@rm -rf lib/SecurityConfigure
