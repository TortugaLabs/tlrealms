#
DESTDIR	= /usr/local
BINDIR	= /bin
MANDIR	= /man
LIBDIR  = /lib/tlr
MANIFY=$(shell pwd)/../tlkit/manify

$(DESTDIR)$(BINDIR)/chpwd: client/chpwd
	install -m 755 $< $@

$(DESTDIR)$(BINDIR)/tlr-adm: client/loader
	install -m 755 $< $@

$(DESTDIR)$(BINDIR)/tlr-agent: client/loader
	install -m 755 $< $@

$(DESTDIR)$(BINDIR)/tlr-ed: client/loader
	install -m 755 $< $@

$(DESTDIR)$(LIBDIR)/tlr-adm: client/tlr-adm
	install -m 755 $< $@

$(DESTDIR)$(LIBDIR)/tlr-ed: client/tlr-ed
	install -m 755 $< $@

$(DESTDIR)$(LIBDIR)/tlr-agent: client/tlr-agent
	install -m 755 $< $@

$(DESTDIR)$(LIBDIR)/pwfix.mk: client/pwfix.mk
	install -m 644 $< $@

$(DESTDIR)$(LIBDIR)/pwfix.pl: client/pwfix.pl
	install -m 644 $< $@

$(DESTDIR)$(LIBDIR)/tlr-agent.service: tlr-agent.service
	install -m 644 $< $@

subdirs:
	mkdir -p \
	    $(DESTDIR)$(BINDIR) \
	    $(DESTDIR)$(LIBDIR) \
	    $(DESTDIR)$(MANDIR)

manpages:
	if [ -f $(MANIFY) ] ; then \
	  mkdir -p $(DESTDIR)$(MANDIR) ; \
	  perl $(MANIFY) --outdir=$(DESTDIR)$(MANDIR) --genman client ; \
	elif type manify ; then \
	   mkdir -p $(DESTDIR)$(MANDIR) ; \
	   manify --outdir=$(DESTDIR)$(MANDIR) --genman client ; \
	fi

install: subdirs manpages \
	$(DESTDIR)$(BINDIR)/chpwd \
	$(DESTDIR)$(BINDIR)/tlr-adm \
	$(DESTDIR)$(BINDIR)/tlr-agent \
	$(DESTDIR)$(BINDIR)/tlr-ed \
	$(DESTDIR)$(LIBDIR)/tlr-adm \
	$(DESTDIR)$(LIBDIR)/tlr-ed \
	$(DESTDIR)$(LIBDIR)/tlr-agent \
	$(DESTDIR)$(LIBDIR)/pwfix.mk \
	$(DESTDIR)$(LIBDIR)/pwfix.pl \
	$(DESTDIR)$(LIBDIR)/tlr-agent.service

	tar -C client -cf - TLR | tar -C $(DESTDIR)$(LIBDIR) -xf -

clean:
	find . -name '*~' | xargs -r rm -v
