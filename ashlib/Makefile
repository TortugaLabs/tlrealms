#
# Build script
#
DESTDIR	= /usr/local
BINDIR	= /bin
MANDIR	= /man
LIBDIR  = /lib/ashlib

#PWD=$(shell pwd)

all:

$(DESTDIR)$(BINDIR)/ashlib: ashlib
	install -m755 $< $@

$(DESTDIR)$(BINDIR)/shlog: shlog
	install -m755 $< $@

$(DESTDIR)$(BINDIR)/shdoc: shdoc
	install -m755 $< $@

$(DESTDIR)$(BINDIR)/spp: spp
	install -m755 $< $@


$(DESTDIR)$(LIBDIR)/ashlib.sh: ashlib.sh
	install -m644 $< $@

$(DESTDIR)$(LIBDIR)/core.sh: core.sh
	install -m644 $< $@

$(DESTDIR)$(LIBDIR)/fixattr.sh: fixattr.sh
	install -m644 $< $@

$(DESTDIR)$(LIBDIR)/fixfile.sh: fixfile.sh
	install -m644 $< $@

$(DESTDIR)$(LIBDIR)/fixlnk.sh: fixlnk.sh
	install -m644 $< $@

$(DESTDIR)$(LIBDIR)/refs.sh: refs.sh
	install -m644 $< $@

$(DESTDIR)$(LIBDIR)/solv_ln.sh: solv_ln.sh
	install -m644 $< $@

$(DESTDIR)$(LIBDIR)/ver.sh: ver.sh
	install -m644 $< $@

$(DESTDIR)$(LIBDIR)/rotate.sh: rotate.sh
	install -m644 $< $@

$(DESTDIR)$(LIBDIR)/network.sh: network.sh
	install -m644 $< $@

$(DESTDIR)$(LIBDIR)/pp.sh: pp.sh
	install -m644 $< $@


subdirs:
	mkdir -p \
	    $(DESTDIR)$(BINDIR) \
	    $(DESTDIR)/$(LIBDIR)

install: subdirs \
	$(DESTDIR)$(BINDIR)/ashlib \
	$(DESTDIR)$(BINDIR)/shlog \
	$(DESTDIR)$(BINDIR)/shdoc \
	$(DESTDIR)$(BINDIR)/spp \
	$(DESTDIR)$(LIBDIR)/ashlib.sh \
	$(DESTDIR)$(LIBDIR)/core.sh \
	$(DESTDIR)$(LIBDIR)/fixattr.sh \
	$(DESTDIR)$(LIBDIR)/fixfile.sh \
	$(DESTDIR)$(LIBDIR)/fixlnk.sh \
	$(DESTDIR)$(LIBDIR)/network.sh \
	$(DESTDIR)$(LIBDIR)/pp.sh \
	$(DESTDIR)$(LIBDIR)/refs.sh \
	$(DESTDIR)$(LIBDIR)/rotate.sh \
	$(DESTDIR)$(LIBDIR)/solv_ln.sh \
	$(DESTDIR)$(LIBDIR)/ver.sh \

clean:
	find . -name '*~' | xargs -r rm -v

