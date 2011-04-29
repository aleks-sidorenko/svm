# Scala Version Manager

## Installation

First you'll need to make sure your system has a c++ compiler.  For OSX, XCode will work, for Ubuntu, the build-essential and libssl-dev packages work.

To install create a folder somewhere in your filesystem with the "`svm.sh`" file inside it.  I put mine in a folder called "`.svm`".

Or if you have `git` installed, then just clone it:

    git clone -b svm git://github.com/toolbear74/svm.git ~/.svm

To activate svm, you need to source it from your bash shell

    . ~/.svm/svm.sh

I always add this line to my ~/.bashrc or ~/.profile file to have it automatically sources upon login.   
Often I also put in a line to use a specific version of scala.
    
## Usage

To download, compile, and install the v0.4.1 release of scala, do this:

    svm install v0.4.1

And then in any new shell just use the installed version:

    svm use v0.4.1

If you want to see what versions are available:

    svm ls

To restore your PATH, you can deactivate it.

    svm deactivate

To set a default Scala version to be used in any new shell, use the alias 'default':

    svm alias default v0.4.1

## Credits

Based on [Node Version Manager][1] by Tim Caswell

  [1]: https://github.com/creationix/nvm
