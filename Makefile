PREFIX ?= /usr/local
BINPREFIX ?= "$(PREFIX)/bin"

default: install

install: 
	@echo "Install bins to $(BINPREFIX)"
	@cp -f ./bin/* $(BINPREFIX)

uninstall:
	@echo "Uninstall..."
	@rm -f $(BINPREFIX)/shellgun $(BINPREFIX)/gun-*

clean:
	@echo "Make clean..."
	@echo "Nothing done."
