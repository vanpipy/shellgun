PREFIX ?= /usr/local
BINPREFIX ?= "$(PREFIX)/bin"

SECURITY_CONF_DIR := scripts/SecurityConfigure
BUILD_SCRIPT := $(SECURITY_CONF_DIR)/build.sh
SRC_FILES := $(wildcard $(SECURITY_CONF_DIR)/src/*.sh)
OUT_FILE := bin/security-configure.sh

default: install

.PHONY: security-configure
security-configure: $(OUT_FILE)

$(OUT_FILE): $(SRC_FILES) $(BUILD_SCRIPT) | bin
	@echo "[MAKE] Building security-configure"
	bash $(BUILD_SCRIPT)

bin:
	@mkdir -p bin

install: security-configure
	@echo "Install bins to $(BINPREFIX)"
	@ls ./bin | grep "^git" | xargs -I {} cp ./bin/{} $(BINPREFIX)/{}
	@cp $(OUT_FILE) $(BINPREFIX)/security-configure.sh
	@chmod +x $(BINPREFIX)/security-configure.sh

uninstall:
	@echo "Uninstall..."
	@ls ./bin | grep "^git" | xargs -I {} rm "$(BINPREFIX)/{}"
	@rm -f "$(BINPREFIX)/security-configure.sh"
	@echo
	@echo "Completed."

clean: clean-security-configure
	@echo "Make clean..."
	@echo "Nothing done."

.PHONY: clean-security-configure
clean-security-configure:
	@rm -f $(OUT_FILE)
	@rm -rf bin/SecurityConfigure
