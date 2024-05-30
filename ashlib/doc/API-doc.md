# API docs

## Modules

* [../ashlib/ashlib.sh](#idb0a72584f652f44505cc50ab36e9469c)
* [../ashlib/cfv.sh](#idadd3027633c60085719010e81c4c9780)
* [../ashlib/core.sh](#ide3f758493d4db8a299a388d73b55c5db)
* [../ashlib/depcheck.sh](#idcdd9ba77ba3b1d0dbe10fe22a28618f4)
* [../ashlib/fixattr.sh](#id7738c8e00610b07fc8f7e31d382d4d9e)
* [../ashlib/fixfile.sh](#idb3f4a11227b2fce56dbc4aa822656b41)
* [../ashlib/fixlnk.sh](#id10c5abe62a3103e392459fb1e75cd4c1)
* [../ashlib/jobqueue.sh](#id68163bbee085e622bb2f588909d1eacf)
* [../ashlib/kvped.sh](#id25fe4270e036fcb4c953cd8914fb1327)
* [../ashlib/mkid.sh](#ida69c0be4b7e90a864044141273fcf0f7)
* [../ashlib/mnt.sh](#id5fdcd11fcffb007a13a15c44d0f9d909)
* [../ashlib/network.sh](#id49ddbe8581cfcca3f4ae80c0e40be661)
* [../ashlib/on_exit.sh](#id8d49b5f942213f86c2fba0b5734777e3)
* [../ashlib/pp.sh](#idd690cceeabefe335292c8c9003aa29fe)
* [../ashlib/randpw.sh](#id603a5c52766e3e2d547a15dfd2316d8b)
* [../ashlib/refs.sh](#id44ac0079991d04dbbbae8d8e61904004)
* [../ashlib/rotate.sh](#id1c235e833ea42ec0e4f340ab8ec81516)
* [../ashlib/sdep.sh](#id7d452ffa213a46cc0ae8d53270a7d55e)
* [../ashlib/shesc.sh](#id474d9299da0f551b4bf1600c539164e9)
* [../ashlib/solv_ln.sh](#id7b2042cd500a40323d21e46ae5294c6a)
* [../ashlib/spk_enc.sh](#id4851fa353a6e93712d81c836dd817ac3)
* [../ashlib/urlencode.sh](#id11944f4a2dcd1ddb0cf01dc178704c57)
* [../ashlib/ver.sh](#id1efb6558eef453d92d114f5b76ecd474)

## Functions

* [_do_shesc](#idd6f421fc61ea34b2ea3e53a26f4afc49) ([../ashlib/shesc.sh](#id474d9299da0f551b4bf1600c539164e9))
* [_kvp_find_sect](#id0f3d7815d4a401ef5f95208ada66a1ac) ([../ashlib/kvped.sh](#id25fe4270e036fcb4c953cd8914fb1327))
* [_kvp_in_sect](#id7462ffcc50dc42b249ddabddf5e3ac9d) ([../ashlib/kvped.sh](#id25fe4270e036fcb4c953cd8914fb1327))
* [_kvpadd](#id3f934cebd2ddce6a08e04ebb9d4b03b3) ([../ashlib/kvped.sh](#id25fe4270e036fcb4c953cd8914fb1327))
* [_kvpappend](#idb8afa0e90487a3109c6acedbfcb38bb3) ([../ashlib/kvped.sh](#id25fe4270e036fcb4c953cd8914fb1327))
* [_kvpparsekvp](#idef48e4d1026fea4cd466653dc44e0d32) ([../ashlib/kvped.sh](#id25fe4270e036fcb4c953cd8914fb1327))
* [assign](#id5db1eaa60f057835d3fc2b85db826e4a) ([../ashlib/refs.sh](#id44ac0079991d04dbbbae8d8e61904004))
* [cfv](#id32a8fdb0ad20b719641b12852f194c50) ([../ashlib/cfv.sh](#idadd3027633c60085719010e81c4c9780))
* [depcheck](#idfa3f719d26478afee3161c5b85e15b18) ([../ashlib/depcheck.sh](#idcdd9ba77ba3b1d0dbe10fe22a28618f4))
* [exit_handler](#id6f97d23361841d5d84a363b4a9d8a4c0) ([../ashlib/on_exit.sh](#id8d49b5f942213f86c2fba0b5734777e3))
* [fatal](#id1afd10b3b94a27a751306edf8b1181a5) ([../ashlib/core.sh](#ide3f758493d4db8a299a388d73b55c5db))
* [find_in_path](#idb5f1f5392ea23b395ebcd52e59e6aca8) ([../ashlib/ashlib.sh](#idb0a72584f652f44505cc50ab36e9469c))
* [find_nic](#id12081a52d75028ff642d30d251d7d7c3) ([../ashlib/network.sh](#id49ddbe8581cfcca3f4ae80c0e40be661))
* [fixattr](#id218c2d5fe72e220edd1d359508657f63) ([../ashlib/fixattr.sh](#id7738c8e00610b07fc8f7e31d382d4d9e))
* [fixfile](#idee0e366ac37af54c53a8d47bb0d3f800) ([../ashlib/fixfile.sh](#idb3f4a11227b2fce56dbc4aa822656b41))
* [fixlnk](#ida6a20a0dc67ec8c40ee084dba4fa129f) ([../ashlib/fixlnk.sh](#id10c5abe62a3103e392459fb1e75cd4c1))
* [get](#idaf40ec2796ee8622c25d6b92cb410638) ([../ashlib/refs.sh](#id44ac0079991d04dbbbae8d8e61904004))
* [gitver](#id9828ba7aec699375958785790aa02f82) ([../ashlib/ver.sh](#id1efb6558eef453d92d114f5b76ecd474))
* [ifind_in_path](#id1a47c9134dc283aa1e2f7fced73be86a) ([../ashlib/ashlib.sh](#idb0a72584f652f44505cc50ab36e9469c))
* [include](#id227b104d97187a5d25c6dc388f56a521) ([../ashlib/ashlib.sh](#idb0a72584f652f44505cc50ab36e9469c))
* [job_queue](#idceb6d281b45a087237a5acf36ab5a657) ([../ashlib/jobqueue.sh](#id68163bbee085e622bb2f588909d1eacf))
* [job_worker](#idd4ff26cb35525ea74323f9696e354d7f) ([../ashlib/jobqueue.sh](#id68163bbee085e622bb2f588909d1eacf))
* [kvped](#id019cf33c03ae41de89e5c78eabb81604) ([../ashlib/kvped.sh](#id25fe4270e036fcb4c953cd8914fb1327))
* [mkid](#idbd9b0f4f69619899d5b0bb0942beec5a) ([../ashlib/mkid.sh](#ida69c0be4b7e90a864044141273fcf0f7))
* [mksym](#id208cc5ab4bca2ccd0887b63beb6bc90b) ([../ashlib/refs.sh](#id44ac0079991d04dbbbae8d8e61904004))
* [on_exit](#idd8ed96350e71536359ad4a70d98832fb) ([../ashlib/on_exit.sh](#id8d49b5f942213f86c2fba0b5734777e3))
* [pp](#id60550e76527b8b2ba727b1ebe4cf688c) ([../ashlib/pp.sh](#idd690cceeabefe335292c8c9003aa29fe))
* [ppCmd](#id7dba605131cad15e5031dd6192c62990) ([../ashlib/pp.sh](#idd690cceeabefe335292c8c9003aa29fe))
* [ppSimple](#id4e868f43e5b92fad410392475e620e6b) ([../ashlib/pp.sh](#idd690cceeabefe335292c8c9003aa29fe))
* [quit](#id01cd14265e80a77e752258dc8e0c4832) ([../ashlib/core.sh](#ide3f758493d4db8a299a388d73b55c5db))
* [randpw](#id7f126f4f8d6653928441d12c1a8d57fe) ([../ashlib/randpw.sh](#id603a5c52766e3e2d547a15dfd2316d8b))
* [rotate](#idae8ace58fd0a1b7d09e2f9c2f14f2aca) ([../ashlib/rotate.sh](#id1c235e833ea42ec0e4f340ab8ec81516))
* [sdep](#id54f8835ff58af7532e9d1c1300b732d4) ([../ashlib/sdep.sh](#id7d452ffa213a46cc0ae8d53270a7d55e))
* [shell_escape](#idb21089f769728dc031642fcbbed5c590) ([../ashlib/shesc.sh](#id474d9299da0f551b4bf1600c539164e9))
* [solv_ln](#idf71a8ba8013352b746aac3ce40c0324f) ([../ashlib/solv_ln.sh](#id7b2042cd500a40323d21e46ae5294c6a))
* [spk_crypt](#id4133a4d66cb489411d3f228d243317fd) ([../ashlib/spk_enc.sh](#id4851fa353a6e93712d81c836dd817ac3))
* [spk_decrypt](#id5c747430a2ad273e1c96fee3ec28d0d5) ([../ashlib/spk_enc.sh](#id4851fa353a6e93712d81c836dd817ac3))
* [spk_encrypt](#idaa2a7604b82d26f323ef2cdc852347eb) ([../ashlib/spk_enc.sh](#id4851fa353a6e93712d81c836dd817ac3))
* [spk_pem_decrypt](#ida86e5e784bf72375e4e784897bfe9865) ([../ashlib/spk_enc.sh](#id4851fa353a6e93712d81c836dd817ac3))
* [spk_pem_encrypt](#idb53ecbad0cc3bedab58f3c845d4d6f25) ([../ashlib/spk_enc.sh](#id4851fa353a6e93712d81c836dd817ac3))
* [spk_private_key](#id42b5033fc1526fe77a3fd5319b047bea) ([../ashlib/spk_enc.sh](#id4851fa353a6e93712d81c836dd817ac3))
* [spk_public_key](#idca0175d57c6acd4844490d352b9f5d57) ([../ashlib/spk_enc.sh](#id4851fa353a6e93712d81c836dd817ac3))
* [sppinc](#id7c85efa7f5d08f20fbc0558a93b47478) ([../ashlib/pp.sh](#idd690cceeabefe335292c8c9003aa29fe))
* [urldecode](#idad5e2ce8c459f15a2ff07db58ed15ff5) ([../ashlib/urlencode.sh](#id11944f4a2dcd1ddb0cf01dc178704c57))
* [urlencode](#id723dc4b6fae95c55eebd48d26063c5e9) ([../ashlib/urlencode.sh](#id11944f4a2dcd1ddb0cf01dc178704c57))
* [warn](#id1318da3b2bfbef192383d53fa7ac1ad0) ([../ashlib/core.sh](#ide3f758493d4db8a299a388d73b55c5db))

* * *

## <a name="idb0a72584f652f44505cc50ab36e9469c"></a>../ashlib/ashlib.sh

This is a implicit module automatically invoked by:

   eval $(ashlib)

The `core` module is included automatically.



### <a name="idb5f1f5392ea23b395ebcd52e59e6aca8"></a>find_in_path

  Find a file in a path

#### USAGE

  find_in_path [--path=PATH] file

#### OPTIONS

* --path=PATH : don't use $PATH but the provided PATH

#### DESC

Find a file in the provided path or PATH environment
variable.

#### RETURNS

0 if found, 1 if not found

#### OUTPUT

full path of found file



### <a name="id1a47c9134dc283aa1e2f7fced73be86a"></a>ifind_in_path

Determines if the specified file is in the path variable

#### USAGE

  ifind_in_path needle haystack_variable

#### ARGS

* needle -- item to find in the path variable
* haystack_variable -- name of the variable contining path

#### RETURNS

0 if found, 1 if not found

#### OUTPUT

full path of found file



### <a name="id227b104d97187a5d25c6dc388f56a521"></a>include

Include an `ashlib` module.

#### USAGE

  include [--once] module [other modules ...]

#### ARGS

* --once|-1 : if specified, modules will not be included more than once
* module -- module to include

#### RETURNS

0 on success, otherwise the number of failed modules.



## <a name="idadd3027633c60085719010e81c4c9780"></a>../ashlib/cfv.sh

Configurable variables

Define variables only if not specified.  It is used to
configure things via environment variables and provide
suitable defaults if there is none.

The way it works is to simply call the command like this:

VARIABLE=value command args

Then in the script, you woudld do:

cfv VARIABLE default



### <a name="id32a8fdb0ad20b719641b12852f194c50"></a>cfv

Define a configurable variable

#### USAGE

   cfv VARNAME value

#### ARGS

* VARNAME -- variable to define
* value -- default to use



## <a name="ide3f758493d4db8a299a388d73b55c5db"></a>../ashlib/core.sh

Some simple misc functions



### <a name="id1afd10b3b94a27a751306edf8b1181a5"></a>fatal

Fatal error

#### USAGE

   fatal message

#### DESC

Show the fatal error on stderr and terminates the script.



### <a name="id01cd14265e80a77e752258dc8e0c4832"></a>quit

Exit with status

#### USAGE

   quit exit_code message

#### DESC

Show the fatal error on stderr and terminates the script with
exit_code.



### <a name="id1318da3b2bfbef192383d53fa7ac1ad0"></a>warn

  Show a warning on stderr

#### USAGE

  warn message



## <a name="idcdd9ba77ba3b1d0dbe10fe22a28618f4"></a>../ashlib/depcheck.sh

### <a name="idfa3f719d26478afee3161c5b85e15b18"></a>depcheck

Check file dependancies

#### USAGE

 depcheck <target> [depends]

#### OPTIONS

* target : file that would be built
* depends : file components used to build target

#### RETURNS

0 if the target needs to be re-build, 1 if target is up-to-date

#### DESC

`depcheck` would do a dependancy check (similar to what `make`
does).  It finds all the files in `depends` and make sure that
all files are older than the target.



## <a name="id7738c8e00610b07fc8f7e31d382d4d9e"></a>../ashlib/fixattr.sh

### <a name="id218c2d5fe72e220edd1d359508657f63"></a>fixattr

Updates file attributes

#### USAGE

  fixattr [options] file

#### OPTIONS

* --mode=mode -- Target file mode
* --user=user -- User to own the file
* --group=group -- Group that owns the file
* file -- file to modify.

#### DESC

This function ensures that the given `file` has the defined file modes,
owner user and owner groups.



## <a name="idb3f4a11227b2fce56dbc4aa822656b41"></a>../ashlib/fixfile.sh

### <a name="idee0e366ac37af54c53a8d47bb0d3f800"></a>fixfile

Function to modify files in-place.

#### USAGE

  fixfile [options] file

#### OPTIONS

* -D -- if specified, containing directory is created.
* --mode=mode -- mode to set permissions to.
* --user=user -- set ownership to user
* --group=group -- set group to group
* --nobackup -- disable creation of backups
* --backupdir=dir -- if specified, backups are saved to the central dir.
* --backupext=ext -- Backups are created by adding ext.  Defaults to "~".
* --filter -- Use filter mode.  The stdin is used as an script that will
    modify stdin (current file) and the stdout is used as the new contents
    of the file.
* --decode -- input is considered to be gzippped|base64 encoded data
* file -- file to modify

#### DESC

Files are modified in-place only if the contents change.  This means
time stamps are kept accordingly.

<stdin> will be used as the contents of the new file unless --filter
is specified.  When in filter mode, the <stdin> is a shell script
that will be executed with <stdin> is the current contents of the
file and <stdout> as the new contents of the file.
Again, file is only written to if its conents change.



## <a name="id10c5abe62a3103e392459fb1e75cd4c1"></a>../ashlib/fixlnk.sh

### <a name="ida6a20a0dc67ec8c40ee084dba4fa129f"></a>fixlnk

Function to update symlinks

#### USAGE

   fixlnk [-D] target lnk

#### ARGS

* -D -- if specified, link directory is created.
* target -- where the link should be pointing to
* lnk -- where the link is to be created

#### DESC

Note that this will first check if the symlink needs to be corrected.
Otherwise no action is taken.



## <a name="id68163bbee085e622bb2f588909d1eacf"></a>../ashlib/jobqueue.sh

### <a name="idceb6d281b45a087237a5acf36ab5a657"></a>job_queue

Run jobs in a queue

#### USAGE

  <job generator> | job_queue [--workers=n] job_cmd [args]

#### OPTIONS

* --workers=n -- number of worker threads (defaults to 4)
* --verbose : output messages
* job_cmd -- command to execute
* args -- optional arguments

#### RETURNS

1 on error

#### DESC




### <a name="idd4ff26cb35525ea74323f9696e354d7f"></a>job_worker

This is the worker thread function



## <a name="id25fe4270e036fcb4c953cd8914fb1327"></a>../ashlib/kvped.sh

### <a name="id0f3d7815d4a401ef5f95208ada66a1ac"></a>_kvp_find_sect

### <a name="id7462ffcc50dc42b249ddabddf5e3ac9d"></a>_kvp_in_sect

### <a name="id3f934cebd2ddce6a08e04ebb9d4b03b3"></a>_kvpadd

### <a name="idb8afa0e90487a3109c6acedbfcb38bb3"></a>_kvpappend

### <a name="idef48e4d1026fea4cd466653dc44e0d32"></a>_kvpparsekvp

### <a name="id019cf33c03ae41de89e5c78eabb81604"></a>kvped

Function to modify INI files in-place.

#### USAGE

  kvped [options] file [modifiers]

#### OPTIONS

* --nobackup -- disable creation of backups
* --backupdir=dir -- if specified, backups are saved to the central dir.
* --backupext=ext -- Backups are created by adding ext.  Defaults to "~".
* file -- file to modify

#### DESC

Files are modified in-place only if the contents change.  This means
time stamps are kept accordingly.

*kvped* will read the given `file` and will apply the respective
modifiers.  The following modifiers are recognized:

* key=value :: Sets the `key` to `value` in the global (default)
  section.
* section.key=value :: sets the `key` in `section` to `value`.
* -key :: If a key begins with `-` it will be deleted.
* -section.key :: The `key` from `section` will be deleted.



## <a name="ida69c0be4b7e90a864044141273fcf0f7"></a>../ashlib/mkid.sh

### <a name="idbd9b0f4f69619899d5b0bb0942beec5a"></a>mkid

## <a name="id5fdcd11fcffb007a13a15c44d0f9d909"></a>../ashlib/mnt.sh

Determine if the given directory is a mount point

### USAGE

is_mounted directory

### ARGS

* directory -- directory mount point

### DESC

Determine if the given directory is a mount point



## <a name="id49ddbe8581cfcca3f4ae80c0e40be661"></a>../ashlib/network.sh

Network functions

Some utilities used to manage network and related tasks



### <a name="id12081a52d75028ff642d30d251d7d7c3"></a>find_nic

find a nic from a MAC address

#### Usage

   find_nic mac

#### ARGS

* mac -- mac address to find (xx:xx:xx:xx:xx)

#### OUTPUT

The device name that belongs to that mac address

#### DESC

Given a mac address, returns the network interface to use in
ifconfig or other commands.



## <a name="id8d49b5f942213f86c2fba0b5734777e3"></a>../ashlib/on_exit.sh

Used to manage multiple exit handlers



### <a name="id6f97d23361841d5d84a363b4a9d8a4c0"></a>exit_handler

Actual exit function

#### USAGE

  trap exit_handler EXIT

#### DESC

Actual function that gets hooked into the standard EXIT trap
and calls all the registered exit handlers.



### <a name="idd8ed96350e71536359ad4a70d98832fb"></a>on_exit

Register a command to be called on exit

#### USAGE

  on_exit exit_command

#### DESC

Adds a shell command to be executed on exit.
Instead of hooking `trap` _cmd_ `exit`, **on_exit** is cumulative,
so multiple calls to **on_exit** will not replace the exit handler
but add to it.

Only single commands are supported.  For more complex **on_exit**
sequences, declare a function and call that instead.



## <a name="idd690cceeabefe335292c8c9003aa29fe"></a>../ashlib/pp.sh

### <a name="id60550e76527b8b2ba727b1ebe4cf688c"></a>pp

Pre-processor
USAGE
	pp < input > output
DESC
Read some textual data and output post-processed data.

Uses HERE_DOC syntax for the pre-processing language.
So for example, variables are expanded directly as `$varname`
whereas commands can be embedded as `$(command call)`.

As additional extension, lines of the form:

```

#####! command

```

Are used to include arbitrary shell commands.  These however
are executed in line (instead of a subshell as in `$(command)`.
This means that commands in `##!` lines can be used to define
variables, macros or include other files.



### <a name="id7dba605131cad15e5031dd6192c62990"></a>ppCmd

Command line `pp` driver

USAGE
	ppCmd [--output=output] -Iinclude-path -Dcmd file.m.ext ...
DESC
Implements a command line interface for the `pp` function

Input files of the form `file.m.ext` are then pre-processed and
the result is named `file.ext`.



### <a name="id4e868f43e5b92fad410392475e620e6b"></a>ppSimple

Pre-processor
USAGE
	ppSimple < input > output
DESC
Read some textual data and output post-processed data.

Uses HERE_DOC syntax for the pre-processing language.
So for example, variables are expanded directly as `$varname`
whereas commands can be embedded as `$(command call)`.



### <a name="id7c85efa7f5d08f20fbc0558a93b47478"></a>sppinc

## <a name="id603a5c52766e3e2d547a15dfd2316d8b"></a>../ashlib/randpw.sh

### <a name="id7f126f4f8d6653928441d12c1a8d57fe"></a>randpw

## <a name="id44ac0079991d04dbbbae8d8e61904004"></a>../ashlib/refs.sh

Symbolic/Reference functions

Let's you add a level of indirection to shell scripts



### <a name="id5db1eaa60f057835d3fc2b85db826e4a"></a>assign

Assigns a value to the named variable

#### USAGE

    assign varname varvalue

#### ARGS

* varname -- variable to assign a value
* value -- value to assign

#### DESC

This function assigns a value to the named variable.  Unlink straight
assignment with `=`, the variable name can be a variable itself referring
to the actual variable.



### <a name="idaf40ec2796ee8622c25d6b92cb410638"></a>get

Returns the value of varname.

#### USAGE

  get varname

#### ARGS

* varname -- variable to lookup.

#### OUTPUT

  value of varname

#### DESC

`get` will display the value of the provided varname.  Unlike direct
references with `$`, the varname can be itself a variable containing
the actual variable to be referenced.



### <a name="id208cc5ab4bca2ccd0887b63beb6bc90b"></a>mksym

create a symbol from a given string

#### USAGE

   mksym txt

#### ARGS

* txt -- text to convert into variable name

#### OUTPUT

sanitized text

#### DESC

Given an arbitrary input text, this creates a suitable symbol for
it.

This function is meant to sanitize text so it is suitable for variable
nameing.



## <a name="id1c235e833ea42ec0e4f340ab8ec81516"></a>../ashlib/rotate.sh

### <a name="idae8ace58fd0a1b7d09e2f9c2f14f2aca"></a>rotate

Function to rotate log files

#### USAGE

   rotate [options] file [files ...]

#### OPTIONS

* --count=n -- number of archive files (defaults to 10)

#### DESC

Rotates a logfile file by subsequently creating up to
count archive files of it. Archive files are
named "file.number[compress-suffix]" where number is the version
number, 0 being the newest and "count-1" the oldest.



## <a name="id7d452ffa213a46cc0ae8d53270a7d55e"></a>../ashlib/sdep.sh

### <a name="id54f8835ff58af7532e9d1c1300b732d4"></a>sdep

## <a name="id474d9299da0f551b4bf1600c539164e9"></a>../ashlib/shesc.sh

Shell escape function.  Quotes strings so they can be safefly included
parsed by eval or in other scripts.



### <a name="idd6f421fc61ea34b2ea3e53a26f4afc49"></a>_do_shesc

### <a name="idb21089f769728dc031642fcbbed5c590"></a>shell_escape

  Escape string for shell parsing

#### USAGE

  shell_escape [options] "string"

#### OPTIONS

* -q : Always include single quotes
* - : End of options

#### DESC

shell_escape will examine the passed string in the
arguments and add any appropriate meta characters so that
it can be safely parsed by a UNIX shell.

It does so by enclosing the string with single quotes (if
it the string contains "unsafe" characters.).  If the string
only contains safe characters, nothing is actually done.



## <a name="id7b2042cd500a40323d21e46ae5294c6a"></a>../ashlib/solv_ln.sh

### <a name="idf71a8ba8013352b746aac3ce40c0324f"></a>solv_ln

Resolves symbolic links so they are relative paths

#### USAGE

    solv_ln target linkname

#### ARGS

* target - target path (as used with `ln -s`)
* linkname - link to be created

#### OUTPUT

Relative path from linkname to target

#### DESC

Given two paths in the same format as creating a symbolic link
using `ln -s`, it will return a relative path from `linknam` to
`target` as if `linknam` was a symbolic link to `target`.

`target` and `linkname` can be provided as absolute or relative
paths.



## <a name="id4851fa353a6e93712d81c836dd817ac3"></a>../ashlib/spk_enc.sh

### <a name="id4133a4d66cb489411d3f228d243317fd"></a>spk_crypt

Encrypt or decrypt `stdin` using a `ssh` public/private key.

#### USAGE

    spk_crypt [--encrypt|--decrypt] [--base64] [--passwd=xxxx] [--public|--private|--auto] <key-file>

#### ARGS


#### --encrypt : set encrypt mode


#### --decrypt : set decrypt mode

* --base64 : if specified, data will be base64 encoded.
* --passwd=xxxx : password for encrypted private key (if any)
* --public : use public key
* --private : use private key
* --auto : key type is determined from file.
* key-file :  key file to use.  If it contains multiple public keys, the first `rsa` key found is used.

#### OUTPUT

Encrypted/Decrypted data



### <a name="id5c747430a2ad273e1c96fee3ec28d0d5"></a>spk_decrypt

Decrypt `stdin` using a `ssh` public/private key.

#### USAGE

    spk_decrypt [--base64] [--passwd=xxxx] [--public|--private|--auto] <key-file>

#### ARGS

* --base64 : if specified, data will be base64 encoded.
* --passwd=xxxx : password for encrypted private key (if any)
* --public : use public key
* --private : use private key
* --auto : key type is determined from file.
* key-file :  key file to use.  If it contains multiple public keys, the first `rsa` key found is used.

#### OUTPUT

Encrypted data



### <a name="idaa2a7604b82d26f323ef2cdc852347eb"></a>spk_encrypt

Encrypt `stdin` using a `ssh` public/private key.

#### USAGE

    spk_encrypt [--base64] [--passwd=xxxx] [--public|--private|--auto] <key-file>

#### ARGS

* --base64 : if specified, data will be base64 encoded.
* --passwd=xxxx : password for encrypted private key (if any)
* --public : use public key
* --private : use private key
* --auto : key type is determined from file.
* key-file :  key file to use.  If it contains multiple public keys, the first `rsa` key found is used.

#### OUTPUT

Encrypted data



### <a name="ida86e5e784bf72375e4e784897bfe9865"></a>spk_pem_decrypt

Decrypt `stdin` using a `PKCS8/PEM` key.

#### USAGE

    spk_decrypt [--base64] <key-file>

#### ARGS

* --base64 : input data is base64 encoded
* key-file : key file to use.

#### OUTPUT

De-crypted data



### <a name="idb53ecbad0cc3bedab58f3c845d4d6f25"></a>spk_pem_encrypt

Encrypt `stdin` using a `PKCS8/PEM` key.

#### USAGE

    spk_pem_encrypt [--base64] <key-file>

#### ARGS

* --base64 : if specified, data will be base64 encoded.
* key-file : key file to use.

#### OUTPUT

Encrypted data



### <a name="id42b5033fc1526fe77a3fd5319b047bea"></a>spk_private_key

Prepare a private key

#### USAGE

    spk_private [--passwd=xxx] <key-file> <output>

#### ARGS

* key-file : key file to use
* output : output file to use
* --passwd=password : password for private key

#### DESC

Reads a OpenSSH private key and create a key file usable by OpenSSL



### <a name="idca0175d57c6acd4844490d352b9f5d57"></a>spk_public_key

Prepare a public key

#### USAGE

    spk_public <key-file> <output>

#### ARGS

* key-file : public key file to use.  Will use the first `rsa` key found
* output : output file to use

#### DESC

Reads a OpenSSH public key and create a key file usable by OpenSSL



## <a name="id11944f4a2dcd1ddb0cf01dc178704c57"></a>../ashlib/urlencode.sh

### <a name="idad5e2ce8c459f15a2ff07db58ed15ff5"></a>urldecode

### <a name="id723dc4b6fae95c55eebd48d26063c5e9"></a>urlencode

## <a name="id1efb6558eef453d92d114f5b76ecd474"></a>../ashlib/ver.sh

### <a name="id9828ba7aec699375958785790aa02f82"></a>gitver


