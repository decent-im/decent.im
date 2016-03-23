DESTDIR ?= /usr/local

default:
	./process_templates

install:
	install -d -g decent.im -m 750 $(DESTDIR)/decent.im
	install -g decent.im -m 750 config $(DESTDIR)/decent.im/
	cp -r files/* $(DESTDIR)
