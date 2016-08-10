#!/bin/bash

# URL=https://pitebustash.win.ansys.com:8443/scm/ebu
URL=ssh://git@pitebustash.win.ansys.com:7999/ebu

REPOS="build buildtools Ansys_CDU_nosync Ansys_CDU_sync thirdparty thirdparty_opensrc thirdparty_vob2 sj_thirdparty CodeDV Core_Addin simulation simplorer core nextgen ansoft bostonvob"

GITSCRIPTDIR=$PWD/buildtools/scripts/git

check_global_user_config()
{
  git config --global http.sslverify true

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

clone_repos()
{

	for repo in $@
	do
    # optionally use local existing clone as cache
    clone_reference=
    if [ -n "$CLONE_REFERENCE" ]; then
      clone_reference="--reference ${CLONE_REFERENCE}/${repo}"
    fi

		if [ ! -d $repo ]; then
			git clone $clone_reference -v ${URL}/${repo}.git || return
		fi
	done

  symfix_repos $@

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

change_origin_and_pull_master_repos()
{
echo "Entering change origin and pull master function"
	for repo in $@
	do
		if [ -d $repo ]; then
			pushd $repo >/dev/null
		
			echo "Changing origin for $repo..."
			# ensure master is current working branch
			git checkout master
			# add pitebustash origin
			git remote set-url origin ${URL}/${repo}.git

			# reassociate master to track origin/master 
			git branch -u origin/master
			# verify
			echo "New origin URL for repo: $repo..."
			git remote -v
			echo "Pulling $repo..."
			git pull
			
			popd >/dev/null
			
			if [ -d "bostonvob" ]; then
				pushd "bostonvob/altra/test" >/dev/null
				if [ -d "ibm" ]; then
					pushd "ibm" >/dev/null
					git checkout master
					git remote set-url origin ${URL}/bostonvob_altra_test_ibm.git
					git branch -u origin/master
					echo "New origin URL for repo: $repo..."
					git remote -v
					git pull
					popd >/dev/null
				fi
				popd >/dev/null
			fi
		fi
	done

}

reset_repos()
{
  if [ ! -d "$GITSCRIPTDIR" ]; then
    echo "buildtools is not present or checked out"
    exit
  fi

  for repo in $@
  do
    if [ -d $repo ]; then
      pushd $repo >/dev/null

      if [ -n "$(git status -s --untracked-files=no)" ]; then
        echo "Uncommitted files in $repo"
        popd >/dev/null
        exit 1
      fi

      echo "Removing symlink fixups in $repo"
      /bin/bash "$GITSCRIPTDIR/undo-symlinks.sh"
      git reset HEAD
      git checkout -f -- .
      popd >/dev/null
    fi
  done

}

update_repos()
{
	for repo in $@
	do
		if [ ! -d $repo ]; then
      continue
		fi

    pushd $repo >/dev/null
    echo "Updating $repo..."

    # transoform short name to fqdn
    sed -i -re 's/(https:\/\/pitebustash):/\1.win.ansys.com:/' .git/config 2>/dev/null

    # on master
    if [ "$(git rev-parse --abbrev-ref HEAD)" == "master" ]; then
      # this is safe, it won't update any file edits in place
      git pull --all
    else # on another branch...
      # this is always safe
      git remote update

      # try and safely update non-checked out branches
      head="$(git symbolic-ref HEAD)"
      git for-each-ref --format="%(refname) %(upstream)" refs/heads | while read ref up; do
        # if there is a tracked remote (and we aren't checked out on the branch)
        if [ -n "$up" -a "$ref" != "$head" ]; then
          mine="$(git rev-parse "$ref" 2>/dev/null)"
          theirs="$(git rev-parse "$up" 2>/dev/null)"
          base="$(git merge-base "$ref" "$up" 2>/dev/null)"
          # if remote is different and local tip is the the merge base
          if [ "$mine" != "$theirs" -a "$mine" == "$base" ]; then
            git update-ref "$ref" "$theirs"
          fi
        fi
      done
    fi

	  popd >/dev/null
	done
  symfix_repos $@
  restore_deleted $@

  # cannot update ourself on windows... notify instead
  if ! cmp $0 "$GITSCRIPTDIR/ebugit.sh" >/dev/null ; then
    read buildtools_branch_name < buildtools/.git/HEAD
    if [ "$buildtools_branch_name" == "ref: refs/heads/master" ]; then
      echo "NOTE: ebugit.sh has been udpated... please perform the following: "
      echo "cp '$GITSCRIPTDIR/ebugit.sh' '$0'"
    fi
  fi
}

symfix_repos()
{
  if [ ! -d "$GITSCRIPTDIR" ]; then
    echo "buildtools is not present or checked out"
    exit
  fi

	for repo in $@
	do
		if [ -d $repo ]; then
			pushd $repo >/dev/null
			echo "Fixing symlinks in $repo..."
      /bin/bash "$GITSCRIPTDIR/fix-symlinks.sh"
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

repair_symlinks()
{
  if [ ! -d "$GITSCRIPTDIR" ]; then
    echo "buildtools is not present or checked out"
    exit
  fi
  source "$GITSCRIPTDIR/shared-functions"

  for repo in $@
  do
    echo "checking $repo"
    pushd $repo >/dev/null

    git ls-files -s -v | grep '^h 120000' | cut -f2 | grep -v '\/lib.*so$' | grep -vi 'mainwin' | \
    while read link
    do
      # skip directories since that symlink obviously worked
      if [ -d "$link" ]; then
        continue
      fi

      if [ ! -e "$link" ]; then
      	rmdir "$link" 2>/dev/null || rm "$link" 2>/dev/null
        git checkout -f "$link"
      fi

      # use file, look for text files
      #file "$link" 2>/dev/null | grep text &>/dev/null || continue
      linecount=$(wc -l "$link" 2>/dev/null | awk '{print $1}')
      if [ $linecount -gt 1 ]; then continue;fi

      # check first line... try and determine if it looks like a path
      head -n1 "$link" | grep '^\.' &>/dev/null || continue

      dest=$(cat "$link")
      extra_out "repairing $link -> $dest"
      ../buildtools/scripts/git/fix-file.sh "$link"

    done

    popd >/dev/null
  done

  restore_deleted $@
}

restore_deleted()
{
  source "$GITSCRIPTDIR/shared-functions"

  for repo in $@
  do
    pushd $repo >/dev/null
      if [ "$(git ls-files -d | wc -l)" -gt 0 ]; then
        echo "Detected deleted files in $repo. Restoring... "
        git ls-files -d | while read f; do
          echo "$repo/$f" | extra_pipe_out
          git checkout "$f"
        done
      fi
    popd >/dev/null
  done
}

switch_release()
{
  local release=$1
  shift;

  # undo symlinks
  reset_repos $@

  for repo in $@
  do
    if [ -d $repo ]; then
      pushd $repo >/dev/null
      echo "Switching to release $release in $repo"
      if ! git show-ref -s refs/heads/"$release" &>/dev/null; then
        if git show-ref -s refs/remotes/origin/"$release" &>/dev/null; then
          git fetch || return # make sure it is up to date
          git checkout -b "$release" origin/"$release" || return
        else
          echo "$repo does not have a $release branch."
        fi
      else
        git checkout "$release" || return
        git pull || return
      fi
      popd >/dev/null
    fi
  done

  # then update symlinks
  update_repos $@
}

check_global_user_config

cmd=$1
shift

# support --reference option
if [ "$cmd" == "clone" ]; then
  if [ "$1" == "--reference" ]; then
    shift
    # must exist and have a buildtools repo present
    if [ -n "$1" -a -d "$1"/buildtools ]; then
      CLONE_REFERENCE=$1
      shift
    else
      cmd=
    fi
  fi
fi

if [ -n "$1" ]; then
  args=$@
elif [ "$cmd" != "foreach" ]; then
  args=$REPOS
fi

case "$cmd" in
  "clone")
    clone_repos $args
  ;;
  "origin_and_pull")
    change_origin_and_pull_master_repos $args  
  ;;
  "origin")
    change_origin $args  
  ;;
  "update")
    update_repos $args
  ;;
	"remove-symlinks")
    reset_repos $args
  ;;
	"remove")
    reset_repos $args
		for repo in $args
		do
			echo cleaning $repo
			rm -rf $repo
		done
  ;;
  "foreach")
    foreach_repos $args
  ;;
  "repair")
    repair_symlinks $args
  ;;
  "hard-update")
    reset_repos $args
    update_repos $args
  ;;
  restore-deleted)
    restore_deleted $args
  ;;
  'switch-release')
    release=$1
    shift
    if [ -n "$1" ]; then
      switch_args=$@
    else
      switch_args=$REPOS
    fi

    case "$release" in
      master|r15)
        shift
        switch_release $release $switch_args
      ;;
      *)
        if [ -n "$release" ]; then
          echo "Release $release is unsupported"
        fi
        echo "Please specify one of the following releases:"
        echo -e "\tr15"
        echo -e "\tmaster"
      ;;
    esac
  ;;
	*)
			echo
			echo "Usage:"
			echo "$0 [clone|update|remove] [[]|repository name|command]"
      echo "Each command runs on all or a named repository"
      echo "  clone     performs the initial clone"
      echo "            [--reference /path/to/existing clone] for using local data as cache"
      echo "  update    runs git pull for each cloned repository"
      echo "  remove    removes all of the cloned repositories"
      echo "  repair    search for symlinks to repair"
      echo "  foreach   runs a command for each cloned repository"
      echo "  hard-update      runs git pull for each cloned repository and recreates all symlinks"
      echo "  remove-symlinks  removes all symlinks"
      echo "  switch-release   changes the release branch checkout and symlink mappings"
      echo "  origin   changes the origin of each clone repo."
      echo "  origin_and_pull    change origin of each cloned repo. and pull"
	;;
esac

