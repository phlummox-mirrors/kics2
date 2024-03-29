########################################################################
# Makefile for KiCS2 compiler and REPL
########################################################################

# The kics2 subdirectory for compiled files
SUBDIR     = .curry/kics2
# ghc options
# see https://ghc.haskell.org/trac/ghc/ticket/7068
GHC_OPTS2  = $(GHC_OPTIMIZATIONS) --make -v1 -cpp -fno-spec-constr
# ghc language extensions for compiling translated Curry programs
GHC_EXTS   = -XMultiParamTypeClasses -XFlexibleInstances -XRelaxedPolyRec
# ghc includes for compiling translated Curry programs
GHC_INCL   = -i$(ROOT)/runtime:$(ROOT)/runtime/idsupplyghc:$(ROOT)/src/$(SUBDIR):$(LIBDIR)/$(SUBDIR)
# Call to ghc binary
GHC_CALL   = "$(GHC)" $(GHC_OPTS) $(GHC_OPTS2) $(GHC_EXTS) $(GHC_INCL)
# The kics2c call
KICS2C     = $(COMP) -v2 --parse-options=-Wall -i$(LIBDIR)
# options for the bootstrapping compiler
CURRY_OPTS =

# Source modules of the compiler (without standard libraries)
COMPILE_DEPS = AbstractHaskell AbstractHaskellGoodies AbstractHaskellPrinter \
               Analysis Classification CompilerOpts EliminateCond Files      \
               LiftCase Message ModuleDeps                                   \
               Names SimpleMake State TransFunctions TransTypes Utils

# Source modules of the REPL (without standard libraries)
REPL_DEPS = Files GhciComm Linker Names RCFile Utils

.PHONY: all
all: CompileBoot updateInstallInfo REPLBoot

.PHONY: bootstrap
bootstrap:
	$(MAKE) clean

	# Create kics2 via PAKCS or other KiCS2 (stage 1)
	@echo "Compiling stage 1"
	$(MAKE) CompileInitial
	cp $(COMP) $(LOCALBIN)/stage1
	$(CLEANCURRY) -r

	# Create kics2 via kics2 (stage 2)
	@echo "Compiling stage 2"
ifeq ($(shell test -x "$(KICS2)" ; echo $$?),0)
	$(MAKE) CompileBoot
else
	# Compile in several steps to avoid memory overflow with PAKCS:
	$(MAKE) $(SUBDIR)/Curry_ModuleDeps.hs
	$(MAKE) $(SUBDIR)/Curry_TransTypes.hs
	$(MAKE) $(SUBDIR)/Curry_TransFunctions.hs
	$(MAKE) CompileBoot
endif
	cp $(COMP) $(LOCALBIN)/stage2
	$(CLEANCURRY) -r

	# Create kics2 via kics2 (stage 3)
	@echo "Compiling stage 3"
	$(MAKE) CompileBoot
	cp $(COMP) $(LOCALBIN)/stage3

	@echo "Compiling REPL"
	$(MAKE) REPLBoot

# faster bootstrap where stage 3 is omitted
.PHONY: fastbootstrap
fastbootstrap:
	if [ ! -x "$(KICS2)" ] ; then echo "KICS2 is required for fastbootstrap!" && exit 1 ; fi

	$(MAKE) clean

	# Create kics2 via KiCS2 (stage 1)
	@echo "Compiling stage 1"
	$(MAKE) CompileInitial
	$(CLEANCURRY) -r

	# Create kics2 via kics2 (stage 2)
	@echo "Compiling stage 2"
	$(MAKE) CompileBoot

	@echo "Compiling REPL"
	$(MAKE) REPLBoot

# clean all intermediate files of the compiler bootstrapping
.PHONY: clean
clean:
	rm -f $(LOCALBIN)/stage[1,2,3] Compile
	rm -f *.hi *.o $(SUBDIR)/*.hi $(SUBDIR)/*.o

.PHONY: cleanall
cleanall: clean
	rm -rf .curry

########################################################################
# Compile
########################################################################

# generate executable for Curry->Haskell compiler via PAKCS or other KiCS2
.PHONY: CompileInitial
CompileInitial: Compile.curry
	mkdir -p $(LOCALBIN)
ifeq ($(shell test -x "$(KICS2)" ; echo $$?),0)
	# to support bootstrapping with a simple KiCS2 bootstrap compiler,
	# we already use in this phase our own (runtime) libraries:
	$(KICS2) $(CURRY_OPTS) :set +local :set ghc "$(GHC_INCL)" :set path $(LIBDIR) :set parser -Wall :set v2 :load Compile :save :quit
	mv Compile $(COMP)
else
	mv $(INSTALLCURRY) $(INSTALLCURRY).bak
	cat $(INSTALLHS) | \
	  sed "s|^import System.Directory|import Directory|" | \
	  sed "s|^import System.IO.Unsafe|import Unsafe|" > $(INSTALLCURRY)
	pakcs $(CURRY_OPTS) :load Compile :save :quit || (mv $(INSTALLCURRY).bak $(INSTALLCURRY) ; exit 1)
	mv $(INSTALLCURRY).bak $(INSTALLCURRY)
	mv Compile $(COMP)
endif

# generate executable for Curry -> Haskell compiler kics2c
.PHONY: CompileBoot
CompileBoot: CompileBoot.hs $(SUBDIR)/Curry_Compile.hs
	mkdir -p $(LOCALBIN)
	$(GHC_CALL) -o $(COMP) $<

# Although $(INSTALLCURRY) is used by the compiler it must not be included
# in the dependencies because for the distribution installation it would
# require a working KICS2 binary *during* installation.
$(SUBDIR)/Curry_Compile.hs: $(COMPILE_DEPS:=.curry)

# recompile installation information and the compiler
.PHONY: updateInstallInfo
updateInstallInfo: $(SUBDIR)/Curry_Installation.hs
	$(MAKE) CompileBoot

########################################################################
# REPL
########################################################################

# generate executable for Curry -> Haskell REPL kics2i
.PHONY: REPLBoot
REPLBoot: REPLBoot.hs $(SUBDIR)/Curry_REPL.hs
	mkdir -p $(LOCALBIN)
	$(GHC_CALL) -o $(REPL) $<

$(SUBDIR)/Curry_REPL.hs: $(REPL_DEPS:=.curry) $(INSTALLCURRY)

$(SUBDIR)/Curry_%.hs: %.curry
	$(KICS2C) $<
