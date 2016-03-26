DESTDIR ?= /usr/local

default:
	true

install:
	mkdir -p $(DESTDIR)/usr/share/decent.im/files
	cp -r files/etc $(DESTDIR)/usr/share/decent.im/files
	cp -r files/sbin $(DESTDIR)
