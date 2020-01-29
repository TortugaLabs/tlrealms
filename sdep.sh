#!/bin/sh
#
# Copyright (c) 2020 Alejandro Liu
# Licensed under the MIT license:
#
# Permission is  hereby granted,  free of charge,  to any  person obtaining
# a  copy  of  this  software   and  associated  documentation  files  (the
# "Software"),  to  deal in  the  Software  without restriction,  including
# without  limitation the  rights  to use,  copy,  modify, merge,  publish,
# distribute, sublicense, and/or sell copies of the Software, and to permit
# persons  to whom  the Software  is  furnished to  do so,  subject to  the
# following conditions:
#
# The above copyright  notice and this permission notice  shall be included
# in all copies or substantial portions of the Software.
#
# THE  SOFTWARE  IS  PROVIDED  "AS  IS",  WITHOUT  WARRANTY  OF  ANY  KIND,
# EXPRESS  OR IMPLIED,  INCLUDING  BUT  NOT LIMITED  TO  THE WARRANTIES  OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
# NO EVENT SHALL THE AUTHORS OR  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR  OTHER LIABILITY, WHETHER  IN AN  ACTION OF CONTRACT,  TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#
sdep() {
  if [ -z "$repo_url" ] ; then
    echo "Must define a repo_url" 1>&2
    exit 1
  fi
  local i k v stxt ctxt rc=0
  for i in "$@"
  do
    k=$(echo $i | cut -d: -f1)
    v=$(echo $i | cut -d: -f2)
    
    stxt=$(wget -O- -nv "$repo_url/$k")
    if [ -z "$stxt" ] ; then
      echo "$k: is an empty file" 1>&2
      rc=1
      continue
    fi
    ctxt=$([ -f "$v" ] && cat "$v")
    if [ x"$stxt" != x"$ctxt" ] ; then
      echo "Updating \"$v\""
      echo "$stxt" > "$v"
    fi
  done
  return $rc
}

