DESTDIR ?= /usr/local

default:
	true

install:
	chmod -R u=r files/etc/cron.d
	mkdir -p $(DESTDIR)/usr/share/decent.im/files
	cp -r files/etc $(DESTDIR)/usr/share/decent.im/files
	cp -r files/sbin $(DESTDIR)
