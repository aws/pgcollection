EXTENSION = collection
EXTVERSION = 0.9
DATA = $(wildcard sql/*.sql)

PGFILEDESC = "pgcollection - collection data type for PostgreSQL"

DOCS = pgcollection.md

MODULE_big = $(EXTENSION)
OBJS =  src/collection.o \
		src/collection_io.o \
		src/collection_userfuncs.o \
		src/collection_subs.o \
		src/collection_parse.o

REGRESS = collection subscript iteration srf
REGRESS_OPTS = --inputdir=test --outputdir=test --load-extension=collection

EXTRA_CLEAN = test/results/ test/regression.diffs test/regression.out $(EXTENSION)-$(EXTVERSION).zip

PG_CPPFLAGS += -I./include/

# enable a bloom filter to speed up finds
PG_CPPFLAGS += -DHASH_BLOOM=16

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

dist:
	git archive --format zip --prefix=$(EXTENSION)-$(EXTVERSION)/ -o $(EXTENSION)-$(EXTVERSION).zip HEAD