PREFIX ?= /usr/local
BINPREFIX ?= "$(PREFIX)/bin"

default: install

install: 
	@echo "Install bins to $(BINPREFIX)"
	@cp -f ./bin/* $(BINPREFIX)

uninstall:
	@echo "Uninstall..."
	@ls ./bin | xargs -I {} rm "$(BINPREFIX)/{}"
	@echo
	@echo "Completed."

clean:
	@echo "Make clean..."
	@echo "Nothing done."
