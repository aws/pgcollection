EXTENSION = collection
EXTVERSION = 1.1.0

PGFILEDESC = "pgcollection - collection data type for PostgreSQL"

DOCS = pgcollection.md

MODULE_big = $(EXTENSION)
OBJS = src/collection.o \
		src/collection_io.o \
		src/collection_userfuncs.o \
		src/collection_subs.o \
		src/collection_parse.o

REGRESS = collection subscript iteration srf select inout_params
REGRESS_OPTS = --inputdir=test --outputdir=test --load-extension=collection

EXTRA_CLEAN = test/results/ test/regression.diffs test/regression.out \
		pgcollection-$(EXTVERSION).zip include/$(EXTENSION)_config.h \
		META.json

DATA = $(wildcard sql/*.sql)
DATA_built = $(EXTENSION).control

PG_CPPFLAGS += -I./include/

# enable a bloom filter to speed up finds
PG_CPPFLAGS += -DHASH_BLOOM=16

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

META.json: META.json.in
	sed 's,EXTVERSION,$(EXTVERSION),g; s,EXTNAME,$(EXTENSION),g' $< > $@;

include/$(EXTENSION)_config.h: include/$(EXTENSION)_config.h.in META.json
	sed 's,EXTVERSION,$(EXTVERSION),g; s,EXTNAME,$(EXTENSION),g;' $< > $@;

$(EXTENSION).control: $(EXTENSION).control.in
	sed 's,EXTVERSION,$(EXTVERSION),g; s,EXTNAME,$(EXTENSION),g' $< > $@;

src/collection.o: include/$(EXTENSION)_config.h

dist:
	git archive --format zip --prefix=pgcollection-$(EXTVERSION)/ -o pgcollection-$(EXTVERSION).zip HEAD
