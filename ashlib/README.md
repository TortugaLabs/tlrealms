ashlib
======

Ashlib is a library that implements useful functions for either bash or sh.

## Copyright

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

## Synopsis

Include in your script:

    eval $(ashlib)

After that you can:

    include _module_

## Available modules

* ashlib.sh  
  Automatically included by `ashlib`.  Defines the `include` function.
* core.sh  
  Basic definitions.
* find_in_path.sh  
  Find if a file exists in a PATH variable.
* fixattr.sh  
  Fix file attributes (ownership and permissions)
* fixfile.sh  
  Update the contents of a file.
* fixlnk.sh  
  Update symbolic links.
* kvped.sh
  Edit "ini" file contents
* mkid.sh  
  Sanitize strings so that they are used as shell variables
* mnt.sh  
  Mounted file system utilities
* network.sh  
  Network related function
* on_exit.sh  
  functions to be executed when a script terminates
* pp.sh  
  bash pre-processor
* refs.sh  
  A reference library
* rotate.sh  
  File rotation script
* sdep.sh  
  Implement soft dependancies
* shesc.sh  
  Escape variables so that they are properly parsed by a shell interpreter
* solv_ln.sh  
  Resolve symbolic links
* spk_enc.sh  
  Encrypt files using SSH Public keys.
* urlencode.sh  
  Escape strings so that they can be used in URLs.
* ver.sh  
  Determine git version information.

## Utility commands

* ashlib  
  Set-up ashlib
* rs
  Run snippets.
* shlog  
  Run a shell while loging stdin.
* shdoc  
  Simple perl (?!?) script to create reference documentation.
* spp
  Shell-like Pre-processor driver

## Installation

A `makefile` is provided.  Installation can be done with:

    make install DESTDIR=/opt

## API

See [API](API-doc.md).

## NOTES

* TODO: revamp Makefile
* TODO: Update docs
* TODO: write unit tests 



