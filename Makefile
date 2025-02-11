# Copyright 2009 The RE2 Authors.  All Rights Reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

# To build against ICU for full Unicode properties support,
# uncomment the next two lines:
# CCICU=$(shell pkg-config icu-uc --cflags) -DRE2_USE_ICU
# LDICU=$(shell pkg-config icu-uc --libs)

# To build against PCRE for testing or benchmarking,
# uncomment the next two lines:
# CCPCRE=-I/usr/local/include -DUSEPCRE
# LDPCRE=-L/usr/local/lib -lpcre

# CXX?=g++
CXX=/opt/wasi-sdk/bin/clang++
# can override
CXXFLAGS=-O3 -g --target=wasm32-wasi -ftls-model=local-exec -fno-exceptions
LDFLAGS?=
# required
# RE2_CXXFLAGS?=-std=c++11 -pthread -Wall -Wextra -Wno-unused-parameter -Wno-missing-field-initializers -I. $(CCICU) $(CCPCRE)
RE2_CXXFLAGS?=-std=c++11 -Wall -Wextra -Wno-unused-parameter -Wno-missing-field-initializers -I. $(CCICU) $(CCPCRE)
RE2_LDFLAGS?=-pthread $(LDICU) $(LDPCRE)
AR=/opt/wasi-sdk/bin/llvm-ar
ARFLAGS?=rsc
NM=/opt/wasi-sdk/bin/llvm-nm
NMFLAGS?=-p

# Variables mandated by GNU, the arbiter of all good taste on the internet.
# http://www.gnu.org/prep/standards/standards.html
prefix=/usr/local
exec_prefix=$(prefix)
includedir=$(prefix)/include
libdir=$(exec_prefix)/lib
INSTALL=install
INSTALL_DATA=$(INSTALL) -m 644

# Work around the weirdness of sed(1) on Darwin. :/
ifeq ($(shell uname),Darwin)
SED_INPLACE=sed -i ''
else ifeq ($(shell uname),SunOS)
SED_INPLACE=sed -i
else
SED_INPLACE=sed -i
endif

# ABI version
# http://tldp.org/HOWTO/Program-Library-HOWTO/shared-libraries.html
SONAME=0

# To rebuild the Tables generated by Perl and Python scripts (requires Internet
# access for Unicode data), uncomment the following line:
# REBUILD_TABLES=1

# The SunOS linker does not support wildcards. :(
ifeq ($(shell uname),Darwin)
SOEXT=dylib
SOEXTVER=$(SONAME).$(SOEXT)
SOEXTVER00=$(SONAME).0.0.$(SOEXT)
MAKE_SHARED_LIBRARY=$(CXX) -dynamiclib -Wl,-install_name,$(libdir)/libre2.$(SOEXTVER),-exported_symbols_list,libre2.symbols.darwin $(RE2_LDFLAGS) $(LDFLAGS)
else ifeq ($(shell uname),SunOS)
SOEXT=so
SOEXTVER=$(SOEXT).$(SONAME)
SOEXTVER00=$(SOEXT).$(SONAME).0.0
MAKE_SHARED_LIBRARY=$(CXX) -shared -Wl,-soname,libre2.$(SOEXTVER) $(RE2_LDFLAGS) $(LDFLAGS)
else
SOEXT=so
SOEXTVER=$(SOEXT).$(SONAME)
SOEXTVER00=$(SOEXT).$(SONAME).0.0
MAKE_SHARED_LIBRARY=$(CXX) -shared -Wl,-soname,libre2.$(SOEXTVER),--version-script,libre2.symbols $(RE2_LDFLAGS) $(LDFLAGS)
endif

all: obj/libre2.a obj/so/libre2.$(SOEXT)

INSTALL_HFILES=\
	re2/filtered_re2.h\
	re2/re2.h\
	re2/set.h\
	re2/stringpiece.h\

HFILES=\
	util/benchmark.h\
	util/flags.h\
	util/logging.h\
	util/malloc_counter.h\
	util/mix.h\
	util/mutex.h\
	util/pcre.h\
	util/strutil.h\
	util/test.h\
	util/utf.h\
	util/util.h\
	re2/bitmap256.h\
	re2/filtered_re2.h\
	re2/pod_array.h\
	re2/prefilter.h\
	re2/prefilter_tree.h\
	re2/prog.h\
	re2/re2.h\
	re2/regexp.h\
	re2/set.h\
	re2/sparse_array.h\
	re2/sparse_set.h\
	re2/stringpiece.h\
	re2/testing/exhaustive_tester.h\
	re2/testing/regexp_generator.h\
	re2/testing/string_generator.h\
	re2/testing/tester.h\
	re2/unicode_casefold.h\
	re2/unicode_groups.h\
	re2/walker-inl.h\

OFILES=\
	obj/util/rune.o\
	obj/util/strutil.o\
	obj/re2/bitstate.o\
	obj/re2/compile.o\
	obj/re2/dfa.o\
	obj/re2/filtered_re2.o\
	obj/re2/mimics_pcre.o\
	obj/re2/nfa.o\
	obj/re2/onepass.o\
	obj/re2/parse.o\
	obj/re2/perl_groups.o\
	obj/re2/prefilter.o\
	obj/re2/prefilter_tree.o\
	obj/re2/prog.o\
	obj/re2/re2.o\
	obj/re2/regexp.o\
	obj/re2/set.o\
	obj/re2/simplify.o\
	obj/re2/stringpiece.o\
	obj/re2/tostring.o\
	obj/re2/unicode_casefold.o\
	obj/re2/unicode_groups.o\

TESTOFILES=\
	obj/util/pcre.o\
	obj/re2/testing/backtrack.o\
	obj/re2/testing/dump.o\
	obj/re2/testing/exhaustive_tester.o\
	obj/re2/testing/null_walker.o\
	obj/re2/testing/regexp_generator.o\
	obj/re2/testing/string_generator.o\
	obj/re2/testing/tester.o\

TESTS=\
	obj/test/charclass_test\
	obj/test/compile_test\
	obj/test/filtered_re2_test\
	obj/test/mimics_pcre_test\
	obj/test/parse_test\
	obj/test/possible_match_test\
	obj/test/re2_test\
	obj/test/re2_arg_test\
	obj/test/regexp_test\
	obj/test/required_prefix_test\
	obj/test/search_test\
	obj/test/set_test\
	obj/test/simplify_test\
	obj/test/string_generator_test\

BIGTESTS=\
	obj/test/dfa_test\
	obj/test/exhaustive1_test\
	obj/test/exhaustive2_test\
	obj/test/exhaustive3_test\
	obj/test/exhaustive_test\
	obj/test/random_test\

SOFILES=$(patsubst obj/%,obj/so/%,$(OFILES))
# We use TESTOFILES for testing the shared lib, only it is built differently.
STESTS=$(patsubst obj/%,obj/so/%,$(TESTS))
SBIGTESTS=$(patsubst obj/%,obj/so/%,$(BIGTESTS))

DOFILES=$(patsubst obj/%,obj/dbg/%,$(OFILES))
DTESTOFILES=$(patsubst obj/%,obj/dbg/%,$(TESTOFILES))
DTESTS=$(patsubst obj/%,obj/dbg/%,$(TESTS))
DBIGTESTS=$(patsubst obj/%,obj/dbg/%,$(BIGTESTS))

obj/%.o: %.cc $(HFILES)
	@mkdir -p $$(dirname $@)
	$(CXX) -c -o $@ $(CPPFLAGS) $(RE2_CXXFLAGS) $(CXXFLAGS) -DNDEBUG $*.cc

obj/dbg/%.o: %.cc $(HFILES)
	@mkdir -p $$(dirname $@)
	$(CXX) -c -o $@ $(CPPFLAGS) $(RE2_CXXFLAGS) $(CXXFLAGS) $*.cc

obj/so/%.o: %.cc $(HFILES)
	@mkdir -p $$(dirname $@)
	$(CXX) -c -o $@ -fPIC $(CPPFLAGS) $(RE2_CXXFLAGS) $(CXXFLAGS) -DNDEBUG $*.cc

obj/libre2.a: $(OFILES)
	@mkdir -p obj
	$(AR) $(ARFLAGS) obj/libre2.a $(OFILES)

obj/dbg/libre2.a: $(DOFILES)
	@mkdir -p obj/dbg
	$(AR) $(ARFLAGS) obj/dbg/libre2.a $(DOFILES)

obj/so/libre2.$(SOEXT): $(SOFILES)
	@mkdir -p obj/so
	$(MAKE_SHARED_LIBRARY) -o obj/so/libre2.$(SOEXTVER) $(SOFILES)
	ln -sf libre2.$(SOEXTVER) $@

obj/dbg/test/%: obj/dbg/libre2.a obj/dbg/re2/testing/%.o $(DTESTOFILES) obj/dbg/util/test.o
	@mkdir -p obj/dbg/test
	$(CXX) -o $@ obj/dbg/re2/testing/$*.o $(DTESTOFILES) obj/dbg/util/test.o obj/dbg/libre2.a $(RE2_LDFLAGS) $(LDFLAGS)

obj/test/%: obj/libre2.a obj/re2/testing/%.o $(TESTOFILES) obj/util/test.o
	@mkdir -p obj/test
	$(CXX) -o $@ obj/re2/testing/$*.o $(TESTOFILES) obj/util/test.o obj/libre2.a $(RE2_LDFLAGS) $(LDFLAGS)

# Test the shared lib, falling back to the static lib for private symbols
obj/so/test/%: obj/so/libre2.$(SOEXT) obj/libre2.a obj/re2/testing/%.o $(TESTOFILES) obj/util/test.o
	@mkdir -p obj/so/test
	$(CXX) -o $@ obj/re2/testing/$*.o $(TESTOFILES) obj/util/test.o -Lobj/so -lre2 obj/libre2.a $(RE2_LDFLAGS) $(LDFLAGS)

# Filter out dump.o because testing::TempDir() isn't available for it.
obj/test/regexp_benchmark: obj/libre2.a obj/re2/testing/regexp_benchmark.o $(TESTOFILES) obj/util/benchmark.o
	@mkdir -p obj/test
	$(CXX) -o $@ obj/re2/testing/regexp_benchmark.o $(filter-out obj/re2/testing/dump.o, $(TESTOFILES)) obj/util/benchmark.o obj/libre2.a $(RE2_LDFLAGS) $(LDFLAGS)

# re2_fuzzer is a target for fuzzers like libFuzzer and AFL. This fake fuzzing
# is simply a way to check that the target builds and then to run it against a
# fixed set of inputs. To perform real fuzzing, refer to the documentation for
# libFuzzer (llvm.org/docs/LibFuzzer.html) and AFL (lcamtuf.coredump.cx/afl/).
obj/test/re2_fuzzer: obj/libre2.a obj/re2/fuzzing/re2_fuzzer.o obj/util/fuzz.o
	@mkdir -p obj/test
	$(CXX) -o $@ obj/re2/fuzzing/re2_fuzzer.o obj/util/fuzz.o obj/libre2.a $(RE2_LDFLAGS) $(LDFLAGS)

ifdef REBUILD_TABLES
re2/perl_groups.cc: re2/make_perl_groups.pl
	perl $< > $@

re2/unicode_%.cc: re2/make_unicode_%.py
	python $< > $@

.PRECIOUS: re2/perl_groups.cc re2/unicode_casefold.cc re2/unicode_groups.cc
endif

distclean: clean
	rm -f re2/perl_groups.cc re2/unicode_casefold.cc re2/unicode_groups.cc

clean:
	rm -rf obj
	rm -f re2/*.pyc

testofiles: $(TESTOFILES)

test: $(DTESTS) $(TESTS) $(STESTS) debug-test static-test shared-test

debug-test: $(DTESTS)
	@./runtests $(DTESTS)

static-test: $(TESTS)
	@./runtests $(TESTS)

shared-test: $(STESTS)
	@./runtests -shared-library-path obj/so $(STESTS)

debug-bigtest: $(DTESTS) $(DBIGTESTS)
	@./runtests $(DTESTS) $(DBIGTESTS)

static-bigtest: $(TESTS) $(BIGTESTS)
	@./runtests $(TESTS) $(BIGTESTS)

shared-bigtest: $(STESTS) $(SBIGTESTS)
	@./runtests -shared-library-path obj/so $(STESTS) $(SBIGTESTS)

benchmark: obj/test/regexp_benchmark

fuzz: obj/test/re2_fuzzer

install: obj/libre2.a obj/so/libre2.$(SOEXT)
	mkdir -p $(DESTDIR)$(includedir)/re2 $(DESTDIR)$(libdir)/pkgconfig
	$(INSTALL_DATA) $(INSTALL_HFILES) $(DESTDIR)$(includedir)/re2
	$(INSTALL) obj/libre2.a $(DESTDIR)$(libdir)/libre2.a
	$(INSTALL) obj/so/libre2.$(SOEXT) $(DESTDIR)$(libdir)/libre2.$(SOEXTVER00)
	ln -sf libre2.$(SOEXTVER00) $(DESTDIR)$(libdir)/libre2.$(SOEXTVER)
	ln -sf libre2.$(SOEXTVER00) $(DESTDIR)$(libdir)/libre2.$(SOEXT)
	$(INSTALL_DATA) re2.pc $(DESTDIR)$(libdir)/pkgconfig/re2.pc
	$(SED_INPLACE) -e "s#@includedir@#$(includedir)#" $(DESTDIR)$(libdir)/pkgconfig/re2.pc
	$(SED_INPLACE) -e "s#@libdir@#$(libdir)#" $(DESTDIR)$(libdir)/pkgconfig/re2.pc

testinstall: static-testinstall shared-testinstall
	@echo
	@echo Install tests passed.
	@echo

static-testinstall: CXXFLAGS:=-std=c++11 -pthread -I$(DESTDIR)$(includedir) $(CXXFLAGS)
static-testinstall: LDFLAGS:=-pthread -L$(DESTDIR)$(libdir) -l:libre2.a $(LDICU) $(LDFLAGS)
static-testinstall:
	@mkdir -p obj
	@cp testinstall.cc obj
ifeq ($(shell uname),Darwin)
	@echo Skipping test for libre2.a on Darwin.
else ifeq ($(shell uname),SunOS)
	@echo Skipping test for libre2.a on SunOS.
else
	(cd obj && $(CXX) testinstall.cc -o testinstall $(CXXFLAGS) $(LDFLAGS))
	obj/testinstall
endif

shared-testinstall: CXXFLAGS:=-std=c++11 -pthread -I$(DESTDIR)$(includedir) $(CXXFLAGS)
shared-testinstall: LDFLAGS:=-pthread -L$(DESTDIR)$(libdir) -lre2 $(LDICU) $(LDFLAGS)
shared-testinstall:
	@mkdir -p obj
	@cp testinstall.cc obj
	(cd obj && $(CXX) testinstall.cc -o testinstall $(CXXFLAGS) $(LDFLAGS))
ifeq ($(shell uname),Darwin)
	DYLD_LIBRARY_PATH="$(DESTDIR)$(libdir):$(DYLD_LIBRARY_PATH)" obj/testinstall
else
	LD_LIBRARY_PATH="$(DESTDIR)$(libdir):$(LD_LIBRARY_PATH)" obj/testinstall
endif

benchlog: obj/test/regexp_benchmark
	(echo '==BENCHMARK==' `hostname` `date`; \
	  (uname -a; $(CXX) --version; git rev-parse --short HEAD; file obj/test/regexp_benchmark) | sed 's/^/# /'; \
	  echo; \
	  ./obj/test/regexp_benchmark 'PCRE|RE2') | tee -a benchlog.$$(hostname | sed 's/\..*//')

# Keep gmake from deleting intermediate files it creates.
# This makes repeated builds faster and preserves debug info on OS X.

.PRECIOUS: obj/%.o obj/dbg/%.o obj/so/%.o obj/libre2.a \
	obj/dbg/libre2.a obj/so/libre2.a \
	obj/test/% obj/so/test/% obj/dbg/test/%

log:
	$(MAKE) clean
	$(MAKE) CXXFLAGS="$(CXXFLAGS) -DLOGGING=1" \
		$(filter obj/test/exhaustive%_test,$(BIGTESTS))
	echo '#' RE2 exhaustive tests built by make log >re2-exhaustive.txt
	echo '#' $$(date) >>re2-exhaustive.txt
	obj/test/exhaustive_test |grep -v '^PASS$$' >>re2-exhaustive.txt
	obj/test/exhaustive1_test |grep -v '^PASS$$' >>re2-exhaustive.txt
	obj/test/exhaustive2_test |grep -v '^PASS$$' >>re2-exhaustive.txt
	obj/test/exhaustive3_test |grep -v '^PASS$$' >>re2-exhaustive.txt

	$(MAKE) CXXFLAGS="$(CXXFLAGS) -DLOGGING=1" obj/test/search_test
	echo '#' RE2 basic search tests built by make $@ >re2-search.txt
	echo '#' $$(date) >>re2-search.txt
	obj/test/search_test |grep -v '^PASS$$' >>re2-search.txt

x: x.cc obj/libre2.a
	g++ -I. -o x x.cc obj/libre2.a
