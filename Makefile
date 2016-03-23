DESTDIR ?= /usr/local

default:
	./process_templates

install:
	install -d -m 750 $(DESTDIR)/etc/decent.im
	install -m 750 config $(DESTDIR)/etc/decent.im/
	cp -r files/* $(DESTDIR)
