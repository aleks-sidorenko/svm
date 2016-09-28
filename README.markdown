# Scala Version Manager

Simple bash script to manage multiple active scala versions

## Installation

To install create a folder somewhere in your filesystem with the "`svm.sh`" file inside it.  To install to a folder called "`.svm`"

    mkdir -p ~/.svm && curl "https://github.com/aleks-sidorenko/svm/raw/svm/svm.sh" -o ~/.svm/svm.sh

Or if you have `git` installed, then just clone it

    git clone -b svm git://github.com/toolbear/svm.git ~/.svm

To activate svm, you need to source it from your bash shell

    . ~/.svm/svm.sh

Add this line to ~/.bashrc or ~/.profile file to have it automatically sourced upon login.
    
## Usage

To download and install the 2.8.1.final release of scala, do this:

    svm install v2.8.1.final

And then in any new shell just use the installed version:

    svm use v2.8.1.final

If you want to see what versions are available:

    svm ls

To restore your PATH, you can deactivate it.

    svm deactivate

To set a default Scala version to be used in any new shell, use the alias 'default':

    svm alias default v2.8.1.final

For full commands and more more usage examples:

    svm help

## Alternatives

* **sbaz** - the [Scala Bazaar System](http://www.scala-lang.org/node/93) managed 3rd party libraries, but can also upgrade your Scala install
* **sbt** - [Simple Build Tool](http://code.google.com/p/simple-build-tool/) can [cross build](http://code.google.com/p/simple-build-tool/wiki/CrossBuild) your project to multiple Scala versions

## Attribution

Based on [Node Version Manager][1] by Tim Caswell

  [1]: https://github.com/creationix/nvm
