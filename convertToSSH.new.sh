#!/bin/bash

# URL=https://pitebustash.win.ansys.com:8443/scm/ebu
URL=ssh://git@pitebustash.win.ansys.com:7999/ebu

REPOS="build buildtools bldtools Ansys_CDU_nosync Ansys_CDU_sync CodeDV Core_Addin simulation simplorer core nextgen ansoft bostonvob"

GITSCRIPTDIR=$PWD/buildtools/scripts/git

check_global_user_config()
{
  
  if ! git config --global user.name &>/dev/null ; then
    echo "You must setup your git user.name configuration"
    echo "run: git config --global user.name 'Your Name'"
    exit 1
  fi
  if ! git config --global user.email &>/dev/null ; then
    echo "You must setup your git user.email configuration"
    echo "run: git config --global user.email 'you@ansys.com'"
    exit 1
  fi
}

change_origin()
{
echo "Entering change origin function"
	for repo in $@
	do
		if [ -d $repo ]; then
			pushd $repo >/dev/null
			# Initial remote
			echo "Initial origin URL for repo: $repo..."
			git remote -v
			
			echo "Changing origin for $repo..."
			# add pitebustash origin
			git remote set-url origin ${URL}/${repo}.git
			# verify
			echo "New origin URL for repo: $repo..."
			git remote -v
			
			popd >/dev/null
		fi
	done

}

foreach_repos()
{
  local doit="$PWD/$$-doit.sh"
  echo "$@" > $doit
  chmod +x "$doit"

  for repo in $REPOS
  do
    if [ -d $repo ]; then
      pushd $repo >/dev/null
      echo "Running $@ in $repo..."
      "$doit"
      echo ""
      popd >/dev/null
    fi
  done

  rm -f "$doit"
}

check_global_user_config
change_origin $REPOS
