# Scala Version Manager
# Implemented as a bash function
# To use source this file from your bash profile
#
# Implemented by Tim Caswell <tim@creationix.com>
# with much bash help from Matthew Ranney

# Auto detect the SVM_DIR
if [ ! -d "$SVM_DIR" ]; then
    export SVM_DIR=$(cd $(dirname ${BASH_SOURCE[0]:-$0}); pwd)
fi

# Emulate curl with wget, if necessary
if [ ! `which curl` ]; then
    if [ `which wget` ]; then
        curl() {
            local ARGS="$* "
            ARGS=${ARGS/-s /-q }
            ARGS=${ARGS/-\# /}
            ARGS=${ARGS/-0 /}
            ARGS=${ARGS/-C - /-c }
            ARGS=${ARGS/-o /-O }

            wget $ARGS
        }
    else
        NOCURL='nocurl'
        curl() { echo 'Need curl or wget to proceed.' >&2; }
    fi
fi

# Expand a version using the version cache
svm_version()
{
    local PATTERN=$1
    local IGNORE=
    local VERSION=''
    if [ -f "$SVM_DIR/alias/$PATTERN" ]; then
        svm_version `cat $SVM_DIR/alias/$PATTERN`
        return
    fi
    # If it looks like an explicit version, don't do anything funny
    if [[ "$PATTERN" == v*.*.* ]]; then
        VERSION="$PATTERN"
    fi
    # The default version is the current one
    if [ ! "$PATTERN" -o "$PATTERN" = 'current' ]; then
        VERSION=`scala -version 2>/dev/null |perl -pe 's/^.*version (\d+\.\d+\.\d+\.[0-9a-zA-Z-]+).*$/\1/g'`
        [ "$VERSION" ] && VERSION="v$VERSION"
    fi
    if [ "$PATTERN" = 'stable' ]; then
        PATTERN='*.*.'
        IGNORE='*.Beta*:*.RC*'
    fi
    if [ "$PATTERN" = 'latest' ]; then
        PATTERN='*.*.'
    fi
    if [ "$PATTERN" = 'all' ]; then
        (cd $SVM_DIR; \ls -dG v* 2>/dev/null || echo "N/A")
        return
    fi
    if [ ! "$VERSION" ]; then
        VERSION=`(setopt GLOB_SUBST 2>/dev/null; GLOBIGNORE=$IGNORE; cd $SVM_DIR; \ls -d v${PATTERN}* 2>/dev/null) | sort -t. -k 1.2,1n -k 2,2n -k 3,3n -k 4,4n | tail -n1`
    fi
    if [ ! "$VERSION" ]; then
        echo "N/A"
        return 13
    elif [ -e "$SVM_DIR/$VERSION" ]; then
        (cd $SVM_DIR; \ls -dG "$VERSION")
    else
        echo "$VERSION"
    fi
}

svm()
{
  if [ $# -lt 1 ]; then
    svm help
    return
  fi
  local VERSION
  case $1 in
    "help" )
      echo
      echo "Scala Version Manager"
      echo
      echo "Usage:"
      echo "    svm help                    Show this message"
      echo "    svm install <version>       Download and install a <version>"
      echo "    svm use <version>           Modify PATH to use <version>"
      echo "    svm ls                      List versions (installed versions are blue)"
      echo "    svm ls <version>            List versions matching a given description"
      echo "    svm deactivate              Undo effects of SVM on current shell"
      echo "    svm sync                    Update the local cache of available versions"
      echo "    svm alias [<pattern>]       Show all aliases beginning with <pattern>"
      echo "    svm alias <name> <version>  Set an alias named <name> pointing to <version>"
      echo
      echo "Example:"
      echo "    svm install v0.4.0          Install a specific version number"
      echo "    svm use stable              Use the stable release"
      echo "    svm install latest          Install the latest, possibly unstable version"
      echo "    svm use 0.2                 Use the latest available 0.2.x release"
      echo "    svm alias default v0.4.0    Set v0.4.0 as the default" 
      echo
    ;;
    "install" )
      if [ $# -ne 2 ]; then
        svm help
        return
      fi
      [ "$NOCURL" ] && curl && return
      VERSION=`svm_version $2`
      if (
        mkdir -p "$SVM_DIR/src" && \
        cd "$SVM_DIR/src" && \
        curl -0 -C - -# "http://www.scala-lang.org/files/archive/scala-${VERSION:1}.tgz" -o "scala-${VERSION:1}.tgz" && \
        tar -xzf "scala-${VERSION:1}.tgz" && \
        rm -rf "$SVM_DIR/$VERSION" && \
        mv "scala-${VERSION:1}" "$SVM_DIR/$VERSION"
        )
      then
        svm use $VERSION
      else
        echo "svm: install $VERSION failed!"
      fi
    ;;
    "deactivate" )
      if [[ $PATH == *$SVM_DIR/*/bin* ]]; then
        export PATH=${PATH%$SVM_DIR/*/bin*}${PATH#*$SVM_DIR/*/bin:}
        echo "$SVM_DIR/*/bin removed from \$PATH"
      else
        echo "Could not find $SVM_DIR/*/bin in \$PATH"
      fi
      if [[ $MANPATH == *$SVM_DIR/*/share/man* ]]; then
        export MANPATH=${MANPATH%$SVM_DIR/*/share/man*}${MANPATH#*$SVM_DIR/*/share/man:}
        echo "$SVM_DIR/*/share/man removed from \$MANPATH"
      else
        echo "Could not find $SVM_DIR/*/share/man in \$MANPATH"
      fi
      unset SVM_BIN
    ;;
    "use" )
      if [ $# -ne 2 ]; then
        svm help
        return
      fi
      VERSION=`svm_version $2`
      if [ ! -d $SVM_DIR/$VERSION ]; then
        echo "$VERSION version is not installed yet"
        return;
      fi
      if [[ $PATH == *$SVM_DIR/*/bin* ]]; then
        PATH=${PATH%$SVM_DIR/*/bin*}$SVM_DIR/$VERSION/bin${PATH#*$SVM_DIR/*/bin}
      else
        PATH="$SVM_DIR/$VERSION/bin:$PATH"
      fi
      if [[ $MANPATH == *$SVM_DIR/*/share/man* ]]; then
        MANPATH=${MANPATH%$SVM_DIR/*/share/man*}$SVM_DIR/$VERSION/share/man${MANPATH#*$SVM_DIR/*/share/man}
      else
        MANPATH="$SVM_DIR/$VERSION/share/man:$MANPATH"
      fi
      export PATH
      export MANPATH
      export SVM_BIN="$SVM_DIR/$VERSION/bin"
      echo "Now using scala $VERSION"
    ;;
    "ls" )
      if [ $# -ne 1 ]; then
        svm_version $2
        return
      fi
      svm_version all
      for P in {stable,latest,current}; do
          echo -ne "$P: \t"; svm_version $P
      done
      svm alias
      echo "# use 'svm sync' to update from scala-lang.org"
    ;;
    "alias" )
      mkdir -p $SVM_DIR/alias
      if [ $# -le 2 ]; then
        (cd $SVM_DIR/alias && for ALIAS in `\ls $2* 2>/dev/null`; do
            local DEST=`cat $ALIAS`
            VERSION=`svm_version $DEST`
            if [ "$DEST" = "$VERSION" ]; then
                echo "$ALIAS -> $DEST"
            else
                echo "$ALIAS -> $DEST (-> $VERSION)"
            fi
        done)
        return
      fi
      if [ ! "$3" ]; then
          rm -f $SVM_DIR/alias/$2
          echo "$2 -> *poof*"
          return
      fi
      mkdir -p $SVM_DIR/alias
      VERSION=`svm_version $3`
      if [ $? -ne 0 ]; then
        echo "! WARNING: Version '$3' does not exist." >&2 
      fi
      echo $3 > "$SVM_DIR/alias/$2"
      if [ ! "$3" = "$VERSION" ]; then
          echo "$2 -> $3 (-> $VERSION)"
          echo "! WARNING: Moving target. Aliases to implicit versions may change without warning."
      else
        echo "$2 -> $3"
      fi
    ;;
    "sync" )
        [ "$NOCURL" ] && curl && return
        local LATEST=`svm_version latest`
        local STABLE=`svm_version stable`
        (cd $SVM_DIR
        rm -f v* 2>/dev/null
        printf "# syncing with scala-lang.org..."
        # For testing download the file.html and run commands against it.
        # curl -s http://www.scala-lang.org/files/archive/ -o file.html
        # cat file.html | grep -o -E 'href="(scala-)[^"#]+(\d+\\.)?(\d+\\.)?(\\*|\d+).tgz"' | cut -d'"' -f2 | sed -E 's/(scala-)(.*).tgz/\2/' | grep -v  "sources\|\-api\|\-devel\-docs\|\-sbaz\|\-jvm4\|tool\-support\|docs"| sort | uniq | sed -e 's/^/v/'
        for VER in `curl -s http://www.scala-lang.org/files/archive/ -o - | grep -o -E 'href="(scala-)[^"#]+(\d+\\.)?(\d+\\.)?(\\*|\d+).tgz"' | cut -d'"' -f2 | sed -E 's/(scala-)(.*).tgz/\2/' | grep -v  "sources\|\-api\|\-devel\-docs\|\-sbaz\|\-jvm4\|tool\-support\|docs"| sort | uniq | sed -e 's/^/v/'`; do
          touch $VER
        done
        echo " done."
        )
        [ "$STABLE" = `svm_version stable` ] || echo "NEW stable: `svm_version stable`"
        [ "$LATEST" = `svm_version latest` ] || echo "NEW latest: `svm_version latest`"
    ;;
    "clear-cache" )
        rm -f $SVM_DIR/v* 2>/dev/null
        echo "Cache cleared."
    ;;
    "version" )
        svm_version $2
    ;;
    * )
      svm help
    ;;
  esac
}

svm ls default >/dev/null 2>&1 && svm use default >/dev/null
