########################################################################
# Makefile for ID compiler
########################################################################

# Is this a global installation (with restricted functionality)(yes/no)?
GLOBALINSTALL=yes
# The major version number:
export MAJORVERSION=0
# The minor version number:
export MINORVERSION=2
# The version date:
COMPILERDATE=25/06/12

# The Haskell installation info
INSTALLHS=runtime/Installation.hs
# The Curry installation info
INSTALLCURRY=src/Installation.curry
# The version information for the manual:
MANUALVERSION=docs/src/version.tex
# Logfile for make:
MAKELOG=make.log
BOOTLOG=boot.log
# The path to the Glasgow Haskell Compiler:
GHC := $(shell which ghc)
# The path to the package configuration file
PKGCONF:= $(shell ghc-pkg --user -v0 list | head -1 | sed "s/://")
# the root directory
export ROOT = ${CURDIR}
# binary directory and executables
export BINDIR=${ROOT}/bin
# Directory where local executables are stored:
export LOCALBIN=${BINDIR}/.local
# Directory where the libraries are located:
export LIBDIR=${ROOT}/lib
export COMP=${LOCALBIN}/kics2c
export REPL=${LOCALBIN}/kics2i

SCRIPTS=cleancurry cymake kics2 makecurrycgi

.PHONY: all
all:
	${MAKE} installwithlogging

# bootstrap the compiler using PAKCS
.PHONY: bootstrap
bootstrap: ${INSTALLCURRY} installscripts
	@rm -f ${BOOTLOG}
	@echo "Bootstrapping started at `date`" > ${BOOTLOG}
	cd src && ${MAKE} bootstrap 2>&1 | tee -a ../${BOOTLOG}
	@echo "Bootstrapping finished at `date`" >> ${BOOTLOG}
	@echo "Bootstrap process logged in file ${BOOTLOG}"

# install the complete system and log the installation process
.PHONY: installwithlogging
installwithlogging:
	@rm -f ${MAKELOG}
	@echo "Make started at `date`" > ${MAKELOG}
	${MAKE} install 2>&1 | tee -a ${MAKELOG}
	@echo "Make finished at `date`" >> ${MAKELOG}
	@echo "Make process logged in file ${MAKELOG}"

# install the complete system if the kics2 compiler is present
.PHONY: install
install: kernel
	cd cpns  && ${MAKE} # Curry Port Name Server demon
	cd tools && ${MAKE} # various tools
	cd www   && ${MAKE} # scripts for dynamic web pages
	# generate manual, if necessary:
	@if [ -d docs/src ] ; \
	 then ${MAKE} ${MANUALVERSION} && cd docs/src && ${MAKE} install ; fi
	# make everything accessible:
	chmod -R go+rX .

# install some scripts of KICS2 in the bin directory:
.PHONY: installscripts
installscripts:
	@if [ ! -d ${BINDIR} ] ; then mkdir -p ${BINDIR} ; fi
	for script in ${SCRIPTS}; do \
          sed "s|^KICS2HOME=.*$$|KICS2HOME=${ROOT}|" < src/$$script.sh       > ${BINDIR}/$$script ; \
        done
	cd ${BINDIR} && chmod 755 ${SCRIPTS}

# install a kernel system without all tools
.PHONY: kernel
kernel: ${INSTALLCURRY} installscripts installfrontend
	${MAKE} Compile
	${MAKE} REPL
	# compile all libraries if the installation is a global one
ifeq ($(GLOBALINSTALL),yes)
	cd runtime && ${MAKE}
	cd lib && ${MAKE} compilelibs
	cd lib && ${MAKE} installlibs
	cd lib && ${MAKE} acy
endif

#
# Create documentation for system libraries:
#
.PHONY: libdoc
libdoc:
	@if [ ! -r bin/currydoc ] ; then \
	  echo "Cannot create library documentation: currydoc not available!" ; exit 1 ; fi
	@rm -f ${MAKELOG}
	@echo "Make libdoc started at `date`" > ${MAKELOG}
	@cd lib && ${MAKE} doc 2>&1 | tee -a ../${MAKELOG}
	@echo "Make libdoc finished at `date`" >> ${MAKELOG}
	@echo "Make libdoc process logged in file ${MAKELOG}"

# install the front end if necessary:
.PHONY: installfrontend
installfrontend:
	@if [ ! -d ${LOCALBIN} ] ; then mkdir -p ${LOCALBIN} ; fi
	# install mcc front end if sources are present:
	@if [ -f mccparser/Makefile ] ; then cd mccparser && ${MAKE} ; fi
	# install local front end if sources are present:
	@if [ -d frontend ] ; then ${MAKE} installlocalfrontend ; fi

# install local front end:
.PHONY: installlocalfrontend
installlocalfrontend:
	cd frontend/curry-base     && cabal install # --force-reinstalls
	cd frontend/curry-frontend && cabal install # --force-reinstalls
	# copy cabal installation of front end into local directory
	@if [ -f ${HOME}/.cabal/bin/cymake ] ; then cp -p ${HOME}/.cabal/bin/cymake ${LOCALBIN} ; fi

.PHONY: Compile
Compile: ${INSTALLCURRY}
	cd src ; ${MAKE} CompileBoot

.PHONY: REPL
REPL: ${INSTALLCURRY}
	cd src ; ${MAKE} REPLBoot

# generate module with basic installation information:
${INSTALLCURRY}: ${INSTALLHS}
	cp ${INSTALLHS} ${INSTALLCURRY}

${INSTALLHS}: Makefile
	@if [ ! -x "${GHC}" ] ; then echo "No executable 'ghc' found in path!" && exit 1; fi
	echo "-- This file is automatically generated, do not change it!" > $@
	echo "module Installation where" >> $@
	echo "" >> $@
	echo 'compilerName :: String' >> $@
	echo 'compilerName = "KiCS2 Curry -> Haskell Compiler"' >> $@
	echo "" >> $@
	echo 'installDir :: String' >> $@
	echo 'installDir = "'`pwd`'"' >> $@
	echo "" >> $@
	echo 'majorVersion :: Int' >> $@
	echo 'majorVersion = ${MAJORVERSION}' >> $@
	echo "" >> $@
	echo 'minorVersion :: Int' >> $@
	echo 'minorVersion = ${MINORVERSION}' >> $@
	echo "" >> $@
	echo 'compilerDate :: String' >> $@
	echo 'compilerDate = "'${COMPILERDATE}'"' >> $@
	echo "" >> $@
	echo 'installDate :: String' >> $@
	echo 'installDate = "'`date`'"' >> $@
	echo "" >> $@
	echo 'ghcExec :: String' >> $@
	echo 'ghcExec = "'${GHC}'" ++ " -package-conf '${PKGCONF}'"' >> $@
	echo "" >> $@
	echo 'installGlobal :: Bool' >> $@
ifeq ($(GLOBALINSTALL),yes)
	echo 'installGlobal = True' >> $@
else
	echo 'installGlobal = False' >> $@
endif

${MANUALVERSION}: Makefile
	echo '\\newcommand{\\kicsversiondate}{Version ${MAJORVERSION}.${MINORVERSION} of ${COMPILERDATE}}' > $@

# install required cabal packages
.PHONY: installhaskell
installhaskell:
	cabal update
	cabal install network
	cabal install parallel
	cabal install tree-monad
	cabal install parallel-tree-search
	cabal install mtl

.PHONY: clean
clean:
	rm -f *.log
	rm -f ${INSTALLHS} ${INSTALLCURRY}
	cd benchmarks && ${MAKE} clean
	cd cpns       && ${MAKE} clean
	@if [ -d lib/.curry/kics2 ] ; then cd lib/.curry/kics2 && rm -f *.hi *.o ; fi
	cd runtime    && ${MAKE} clean
	cd src        && ${MAKE} clean
	cd tools      && ${MAKE} clean
	cd www        && ${MAKE} clean

# clean everything (including compiler binaries)
.PHONY: cleanall
cleanall: clean
	bin/cleancurry -r
	rm -rf ${LOCALBIN}
#	cd ${BINDIR} && rm -f ${SCRIPTS}


###############################################################################
# Create distribution versions of the complete system as tar file kics2.tar.gz:

# temporary directory to create distribution version
KICS2DIST=/tmp/kics2
# repository with new front-end:
FRONTENDREPO=git://git-ps.informatik.uni-kiel.de/curry

# install the sources of the front end from its repository
.PHONY: frontendsources
frontendsources:
	if [ -d frontend ] ; then \
	 cd frontend/curry-base && git pull && cd ../curry-frontend && git pull ; \
	 else mkdir frontend && cd frontend && \
	      git clone ${FRONTENDREPO}/curry-base.git && \
	      git clone ${FRONTENDREPO}/curry-frontend.git ; fi

# generate a source distribution of KICS2:
.PHONY: dist
dist:
	rm -rf kics2.tar.gz ${KICS2DIST}           # remove old distribution
	git clone . ${KICS2DIST}                   # create copy of git version
	cd ${KICS2DIST} && ${MAKE} installscripts ; \
	# copy or install front end sources in distribution:
	if [ -d frontend ] ; then \
	  cp -pr frontend ${KICS2DIST} ; \
	else \
	  cd ${KICS2DIST} && ${MAKE} frontendsources ; \
	fi
	# generate compile and REPL in order to have the bootstrapped
	# Haskell translations in the distribution:
	mkdir -p ${KICS2DIST}/bin/.local
	cp bin/.local/kics2c ${KICS2DIST}/bin/.local/ # copy bootstrap compiler
	cd ${KICS2DIST} && ${MAKE} Compile            # translate compiler
	cd ${KICS2DIST} && ${MAKE} REPL               # translate REPL
	cd ${KICS2DIST} && ${MAKE} clean              # clean object files
	cd ${KICS2DIST} && ${MAKE} cleandist          # delete unnessary files
	# copy documentation:
	@if [ -f docs/Manual.pdf ] ; then cp docs/Manual.pdf ${KICS2DIST}/docs ; fi
	cat Makefile | sed -e "/distribution/,\$$d" | sed 's|^GLOBALINSTALL=.*$$|GLOBALINSTALL=yes|' > ${KICS2DIST}/Makefile
	cd /tmp && tar cf kics2.tar kics2 && gzip kics2.tar
	mv /tmp/kics2.tar.gz .
	chmod 644 kics2.tar.gz
	rm -rf ${KICS2DIST}
	@echo "----------------------------------------------------------------"
	@echo "Distribution kics2.tar.gz generated."

#
# Clean all files that should not be included in a distribution
#
.PHONY: cleandist
cleandist:
	rm -rf .git .gitignore bin/.gitignore
	cd frontend/curry-base     && rm -rf .git .gitignore dist
	cd frontend/curry-frontend && rm -rf .git .gitignore dist
	rm -rf bin # clean executables
	rm -rf docs/src
	rm -rf benchmarks papers talks tests examples experiments
	rm -f TODO compilerdoc.wiki testsuite/TODO

# publish the distribution files in the local web pages
HTMLDIR=${HOME}/public_html/kics2/download
.PHONY: publish
publish:
	cp kics2.tar.gz docs/INSTALL.html ${HTMLDIR}
	chmod -R go+rX ${HTMLDIR}
	@echo "Don't forget to run 'update-kics2' to make the update visible!"
