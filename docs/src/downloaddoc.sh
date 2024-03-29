#!/bin/sh

# The documentation of the tools for PAKCS or KiCS2 packaged by CPM
# is usually stored in the package directory `src`.
# In order to generate a single manual for PAKCS or KiCS2 including
# also the description of the most relevant tools, we download and
# copy the current tool documentations with this script into
# the documentation directory `TOOLDOCDIR`.
# Hence, this script should be executed whenever some tool documentation
# is updated.

# the directory where all tool documentations are stored:
TOOLDOCDIR=tooldocs

# the tool packages where documentation should be downloaded:
TOOLPKGS="currybrowse casc cass cpm currycheck currydoc currypp ertools peval runcurry spicey transbooleq verify"

README=$TOOLDOCDIR/README

mkdir -p $TOOLDOCDIR
echo "This directory contains the documentation of various Curry tools." > $README
echo "It has been automatically generated from the tool packages." >> $README

for T in $TOOLPKGS ; do
    echo "Downloading $T..."
    cpm checkout $T
    rm -rf $TOOLDOCDIR/$T
    cp -r $T/docs $TOOLDOCDIR/$T
    rm -rf $T
    echo "Documentation for package $T downloaded!"
done
