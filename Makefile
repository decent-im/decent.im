DESTDIR ?= /usr/local

default:
	true

install:
	chmod -R u=r,g=,o= files/etc/cron.d
	mkdir -p $(DESTDIR)/share/decent.im/files
	cp -r files/etc files/var $(DESTDIR)/share/decent.im/files
	cp -r files/sbin $(DESTDIR)
