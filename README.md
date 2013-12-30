# TAILS and rEFInd for Mac OS X

This project is intended to make getting started with the TAILS operating system easier.

There are two compontents:

```bash
$ . tails/install.sh
```
This will download and install the [TAILS](https://tails.boum.org/) operating system
on a connected USB drive. THIS WILL OVERWRITE ALL DATA ON THE DRIVE.  Make sure you select
the right one.  The script requires [wget](http://www.gnu.org/software/wget/) and
[gpg2](http://www.gnupg.org/), and will attempt to download these tools via Homebrew if
they aren't present already.

```bash
$ . refind/install.sh
```
This will download and install the [rEFInd](http://www.rodsbooks.com/refind/) boot manager
which should allow you pick between TAILS and Mac OS X when you boot up your system.  The
script requires wget.  The script tries to intelligently set rEFInd defaults based on
whether or not you have FileVault enabled.
