#
# Post processing make script
#
# TSTDAT = .
# ETCDIR = $(TSTDAT)/etc
# SRCDIR = $(ETCDIR)/tlr-data
# VAR_DB = $(TSTDAT)/var-db
# ROOT_KEYS = $(TSTDAT)/auth_keys
# TLRLIB = .
# GRN_USERS = users
# GRI_USERS = 11000


AWK = awk
MAKEDB = makedb --quiet
PWFIX = perl $(TLRLIB)/pwfix.pl -v --users=$(GRN_USERS) --gid=$(GRI_USERS)
DD = dd
TOUCH = touch

all: $(VAR_DB)/shadow.db $(VAR_DB)/passwd.db $(VAR_DB)/group.db \
	$(ETCDIR)/ssh/known_hosts $(ROOT_KEYS)

$(VAR_DB)/shadow.db: $(SRCDIR)/shadow.tmp
	@echo -n "shadow.db... "
	@$(AWK) 'BEGIN { FS=":"; OFS=":" } \
		 /^[ \t]*$$/ { next } \
		 /^[ \t]*#/ { next } \
		 /^[^#]/ { printf ".%s ", $$1; print }' $^ | \
	(umask 077 && $(MAKEDB) -o $@ -)
#	chown 0 $@; chgrp 0 $@; chmod 600 $@
	@echo "done."
#	@if chgrp shadow $@ 2>/dev/null; then \
#	  chmod g+r $@; \
#	else \

#	  echo; \
#	  echo "Warning: The shadow password database $@"; \
#	  echo "has been set to be readable only by root.  You may want"; \
#	  echo "to make it readable by the \`shadow' group depending"; \
#	  echo "on your configuration."; \
#	  echo; \
#	fi


$(VAR_DB)/group.db: $(SRCDIR)/group.tmp
	@echo -n 'group.db...'
	@$(AWK) 'BEGIN { FS=":"; OFS=":" } \
		 /^[ \t]*$$/ { next } \
		 /^[ \t]*#/ { next } \
		 /^[^#]/ { printf ".%s ", $$1; print; \
			   printf "=%s ", $$3; print; \
			   if ($$4 != "") { \
			     split($$4, grmems, ","); \
			     for (memidx in grmems) { \
			       mem=grmems[memidx]; \
			       if (members[mem] == "") \
				 members[mem]=$$3; \
			       else \
				 members[mem]=members[mem] "," $$3; \
			     } \
			     delete grmems; } } \
		 END { for (mem in members) \
			 printf ":%s %s %s\n", mem, mem, members[mem]; }' $^ | \
	$(MAKEDB) -o $@ -
	@echo "done."


$(VAR_DB)/passwd.db: $(SRCDIR)/passwd
	@echo -n 'passwd.db... '
	@$(AWK) 'BEGIN { FS=":"; OFS=":" } \
		 /^[ \t]*$$/ { next } \
		 /^[ \t]*#/ { next } \
		 /^[^#]/ { printf ".%s ", $$1; print; \
			   printf "=%s ", $$3; print }' $^ | \
	$(MAKEDB) -o $@ -
	@echo "done."

$(SRCDIR)/group.tmp: $(SRCDIR)/passwd $(SRCDIR)/group $(ETCDIR)/group
	@$(PWFIX) group $@ $^
	@$(PWFIX) grpfix $@ $^
	@$(TOUCH) $@

$(SRCDIR)/shadow.tmp: $(SRCDIR)/passwd $(SRCDIR)/shadow $(SRCDIR)/pwds
	@$(PWFIX) shadow $@ $^
	@$(TOUCH) $@

$(ETCDIR)/ssh/known_hosts: $(SRCDIR)/known_hosts
	$(DD) if=$^ of=$@

$(ROOT_KEYS): $(SRCDIR)/admin_keys
	mkdir -p $$(dirname $@)
	$(AWK) '{ print $$2,$$3 }' $^ | $(DD) of=$@
