#!/bin/bash

REPOS="buildtools Ansys_CDU_nosync Ansys_CDU_sync thirdparty thirdparty_opensrc thirdparty_vob2 sj_thirdparty CodeDV Core_Addin simplorer nextgen ansoft bostonvob"
GITSCRIPTDIR=$PWD/buildtools/scripts/git

if [ ! -d "$GITSCRIPTDIR" ]; then
    echo "buildtools is not present or checked out"
    exit
fi

# Run symlink cleanup on old version
for repo in $REPOS
do
    if [ -d $repo ]; then
        pushd $repo >/dev/null
        echo "Removing symlink fixups in $repo"
        /bin/bash "$GITSCRIPTDIR/win-undo-symlinks.sh"
        git checkout -f master &>/dev/null
        git reset HEAD >/dev/null
        git checkout -f -- .
        popd >/dev/null
    fi
done

# Pull in new symlink changes
# DEBUG: Currently modified to p
for repo in $REPOS
do
    if [ -d $repo ]; then
        pushd $repo >/dev/null
        echo "Updating $repo..."
        git pull origin master
        popd >/dev/null
    fi
done

# Make sure ebugit.sh gets updated
cp buildtools/scripts/git/ebugit.sh ./

# Run new version of symlink fixup
for repo in $REPOS
do
    if [ -d $repo ]; then
        pushd $repo >/dev/null
        echo "Creating symlinks in $repo..."
        /bin/bash "$GITSCRIPTDIR/fix-symlinks.sh"
        popd >/dev/null
    fi
done

