
VERBOSE=0
TEST_FILES = t/*.t
INST_LIB=.
INST_ARCHLIB=.

all:
	@echo This is currently a dummy make file for \"make test\"

test:
	@PERL_DL_NONLAZY=1 perl "-MExtUtils::Command::MM" "-MTest::Harness" -e "undef *Test::Harness::Switches; test_harness($(VERBOSE), '.')" t/*.t

.PHONY: test all
