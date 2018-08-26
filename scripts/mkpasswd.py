#!/usr/bin/python
"""Replacement for htpasswd"""
# Original author: Eli Carter
# Source: https://gist.github.com/eculver/1420227

import os
import sys
import random
import md5

# We need a crypt module, but Windows doesn't have one by default.  Try to find
# one, and tell the user if we can't.
try:
  import crypt
except ImportError:
  try:
    import fcrypt as crypt
  except ImportError:
    sys.stderr.write("Cannot find a crypt module.  "
			"Possibly http://carey.geek.nz/code/python-fcrypt/\n")
    sys.exit(1)


def gen_salt(len = 8):
  """Returns a string of <len> randome letters"""
  letters = 'abcdefghijklmnopqrstuvwxyz' \
	    'ABCDEFGHIJKLMNOPQRSTUVWXYZ' \
	    '0123456789/.'
  salt = ''
  for x in range(len):
    salt = salt + random.choice(letters)
  return salt

def md5crypt(password, salt, magic='$1$'):
    # /* The password first, since that is what is most unknown */ /* Then our magic string */ /* Then the raw salt */
    m = md5.new()
    m.update(password + magic + salt)

    # /* Then just as many characters of the MD5(pw,salt,pw) */
    mixin = md5.md5(password + salt + password).digest()
    for i in range(0, len(password)):
        m.update(mixin[i % 16])

    # /* Then something really weird... */
    # Also really broken, as far as I can tell.  -m
    i = len(password)
    while i:
        if i & 1:
            m.update('\x00')
        else:
            m.update(password[0])
        i >>= 1

    final = m.digest()

    # /* and now, just to make sure things don't run too fast */
    for i in range(1000):
        m2 = md5.md5()
        if i & 1:
            m2.update(password)
        else:
            m2.update(final)

        if i % 3:
            m2.update(salt)

        if i % 7:
            m2.update(password)

        if i & 1:
            m2.update(final)
        else:
            m2.update(password)

        final = m2.digest()

    # This is the bit that uses to64() in the original code.

    itoa64 = './0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'

    rearranged = ''
    for a, b, c in ((0, 6, 12), (1, 7, 13), (2, 8, 14), (3, 9, 15), (4, 10, 5)):
        v = ord(final[a]) << 16 | ord(final[b]) << 8 | ord(final[c])
        for i in range(4):
            rearranged += itoa64[v & 0x3f]; v >>= 6

    v = ord(final[11])
    for i in range(2):
        rearranged += itoa64[v & 0x3f]; v >>= 6

    return magic + salt + '$' + rearranged

def read_passwd():
  sys.stderr.write("Password: ")
  pwd_in = sys.stdin.readline()
  return pwd_in.rstrip()


def main():
  """%prog [-0|--des|-1|--md5|-5|--sha256|-6|--sha512|-A|--htpasswd|-D|--htdigest user realm] [-S|--salt salt] [password]
  Generate password"""

  args = sys.argv
  args.pop(0)

  def syntax_error(msg):
    """Utility function for displaying fatal error messages with usage
    help.
    """
    sys.stderr.write("Syntax error: " + msg + "\n")
    sys.stderr.write(main.__doc__)
    sys.exit(1)

  hid, slen, presalted = ('$6$', 16, '')

  while len(args):
    if args[0] == '-0' or args[0] == '--des':
      hid, slen = ( '', 2 )
    elif args[0] == '-1' or args[0] == '--md5':
      hid, slen = ( '$1$', 8 )
    elif args[0] == '-5' or args[0] == '--sha256':
      hid, slen = ( '$5$', 16 )
    elif args[0] == '-6' or args[0] == '--sha512':
      hid, slen = ( '$6$', 16 )
    elif args[0] == '-A' or args[0] == '--htpasswd':
      hid, slen = ( '$apr1$', 8 )
    elif args[0] == '-S' or args[0] == '--salt':
      if len(args) < 2:
	syntax_error("presalt requires a salt specification")
      args.pop(0)
      presalted = args[0]
    elif args[0] == '-D' or args[0] == '--htdigest':
      if len(args) < 3:
	syntax_error("htdigest requires user and realm specifications")
      args.pop(0)
      user = args.pop(0)
      realm = args.pop(0)
      if len(args):
	pwd_in = " ".join(args)
      else:
	pwd_in = read_passwd()
      m = md5.new()
      m.update(user + ":" + realm + ":" + pwd_in)
      print realm + ":" + m.hexdigest()
      sys.exit(0)
    else:
      break
    args.pop(0)

  if len(args):
    pwd_in = " ".join(args)
  else:
    pwd_in = read_passwd()


  #~ print "PRESALT: (%s)" % presalted
  #~ print "%s - %d" % (hid, slen)
  if presalted != '':
    # OK, we want to verify a password...
    if presalted[:6] == '$apr1$':
      pwd_out = md5crypt(pwd_in, presalted[6:],'$apr1$')
    else:
      pwd_out = crypt.crypt(pwd_in, presalted)
  elif hid == '$apr1$':
    salt = gen_salt(slen)
    pwd_out = md5crypt(pwd_in, salt, hid)
  else:
    salt = gen_salt(slen)
    pwd_out = crypt.crypt(pwd_in, hid + salt)

  print pwd_out



if __name__ == '__main__':
  main()
