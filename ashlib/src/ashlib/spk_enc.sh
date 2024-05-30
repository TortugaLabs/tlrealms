#!/bin/sh
#
# Some SSL/SSH related encryption functions
#

spk_public_key() {
## Prepare a public key
## # USAGE
##     spk_public <key-file> <output>
## # ARGS
## * key-file : public key file to use.  Will use the first `rsa` key found
## * output : output file to use
## # DESC
## Reads a OpenSSH public key and create a key file usable by OpenSSL
##
  local pubkey="$1" output="$2"
  [ ! -f "$pubkey" ] && return 1 || :
  pubkey=$(awk '$1 == "ssh-rsa" { print ; exit }' < "$pubkey")
  [ -z "$pubkey" ] && return 2 || :

  local w=$(mktemp) rc=0
  (
    echo "$pubkey" > "$w"
    ssh-keygen -e -f "$w" -m PKCS8 > "$output"
  ) || rc=$?
  rm -f "$w"
  return $rc
}

spk_private_key() {
## Prepare a private key
## # USAGE
##     spk_private [--passwd=xxx] <key-file> <output>
## # ARGS
## * key-file : key file to use
## * output : output file to use
## * --passwd=password : password for private key
## # DESC
## Reads a OpenSSH private key and create a key file usable by OpenSSL
##
  local passin=""
  while [ $# -gt 0 ]
  do
    case "$1" in
      --passwd=*) passin="${1#--passwd=}" ;;
      *) break
    esac
    shift
  done

  local privkey="$1" output="$2"
  [ ! -f "$privkey" ] && return 1 || :

  local w=$(mktemp) rc=0
  (
    cp -a "$privkey" "$w"
    if [ -n "$passin" ] ; then
      ssh-keygen -p -N '' -P "$passin" -f "$w" -m pem >/dev/null
    else
      ssh-keygen -p -N '' -f "$w" -m pem >/dev/null
    fi
    cp "$w" "$output"
  ) || rc=$?
  rm -f "$w"
  return $rc
}

spk_pem_encrypt() {
## Encrypt `stdin` using a `PKCS8/PEM` key.
## # USAGE
##     spk_pem_encrypt [--base64] <key-file>
## # ARGS
## * --base64 : if specified, data will be base64 encoded.
## * key-file : key file to use.
## # OUTPUT
## Encrypted data
  local encode=false
  while [ $# -gt 0 ]
  do
    case "$1" in
      --base64) encode=true ;;
      --no-base64) encode=false ;;
      *) break
    esac
    shift
  done

  local keyfile="$1"
  [ ! -f "$keyfile" ] && return 1 || :

  local w=$(mktemp -d) rc=0
  (
    openssl rand -out "$w/secret.key" 32
    openssl rsautl -encrypt -oaep -pubin -inkey "$keyfile" -in "$w/secret.key" -out "$w/secret.key.enc"
    base64 < "$w/secret.key.enc"
    echo ""
    openssl aes-256-cbc -pass file:$w/secret.key $($encode && echo -a)
  ) || rc=$?
  rm -rf "$w"
  return $rc
}

spk_pem_decrypt() {
## Decrypt `stdin` using a `PKCS8/PEM` key.
## # USAGE
##     spk_decrypt [--base64] <key-file>
## # ARGS
## * --base64 : input data is base64 encoded
## * key-file : key file to use.
## # OUTPUT
## De-crypted data
  local encoded=false
  while [ $# -gt 0 ]
  do
    case "$1" in
      --base64) encoded=true ;;
      --no-base64) encoded=false ;;
      *) break
    esac
    shift
  done

  local keyfile="$1"
  [ ! -f "$keyfile" ] && return 1 || :

  local w=$(mktemp -d) rc=0
  (
    local keydat="" line
    while read -r line
    do
      [ -z "$line" ] && break || :
      keydat="$keydat$line"
    done

    echo "$keydat" | base64 -d > $w/secret.key.enc

    openssl rsautl -decrypt -oaep -inkey "$keyfile" -in "$w/secret.key.enc" -out "$w/secret.key"
    openssl aes-256-cbc -d -pass file:$w/secret.key $($encoded && echo -a)
  ) || rc=$?
  rm -rf "$w"
  return $rc
}

spk_crypt() {
## Encrypt or decrypt `stdin` using a `ssh` public/private key.
## # USAGE
##     spk_crypt [--encrypt|--decrypt] [--base64] [--passwd=xxxx] [--public|--private|--auto] <key-file>
## # ARGS
## # --encrypt : set encrypt mode
## # --decrypt : set decrypt mode
## * --base64 : if specified, data will be base64 encoded.
## * --passwd=xxxx : password for encrypted private key (if any)
## * --public : use public key
## * --private : use private key
## * --auto : key type is determined from file.
## * key-file :  key file to use.  If it contains multiple public keys, the first `rsa` key found is used.
## # OUTPUT
## Encrypted/Decrypted data
  local encode=false key=auto passwd="" ktype=auto mode=''
  while [ $# -gt 0 ]
  do
    case "$1" in
      --encrypt) mode=encrypt ;;
      --decrypt) mode=decrypt ;;
      --base64) encode=true ;;
      --no-base64) encode=false ;;
      --passwd=*) passwd=${1#--passwd=} ;;
      --public) ktype=public ;;
      --private) ktype=private ;;
      --auto) ktype=auto ;;
      *) break
    esac
    shift
  done

  [ -z "$mode" ] && return 2 || :
  local keyfile="$1"
  [ ! -f "$keyfile" ] && return 1 || :

  case "$ktype" in
  public|private) : ;;
  *)
    # Auto detect key type...
    if grep -q -e -BEGIN.*PRIVATE' 'KEY- "$keyfile" ; then
      ktype=private
    else
      ktype=public
    fi
    ;;
  esac

  local w=$(mktemp) rc=0
  (
    case "$ktype" in
      public) spk_public_key "$keyfile" "$w" ;;
      private) spk_private_key --passwd="$passwd" "$keyfile" "$w" ;;
    esac

    case "$mode" in
      encrypt) spk_pem_encrypt $($encode && echo --base64) "$w" ;;
      decrypt) spk_pem_decrypt $($encode && echo --base64) "$w" ;;
    esac
  ) || rc=$?
  rm -f "$w"
  return $rc
}

spk_encrypt() {
## Encrypt `stdin` using a `ssh` public/private key.
## # USAGE
##     spk_encrypt [--base64] [--passwd=xxxx] [--public|--private|--auto] <key-file>
## # ARGS
## * --base64 : if specified, data will be base64 encoded.
## * --passwd=xxxx : password for encrypted private key (if any)
## * --public : use public key
## * --private : use private key
## * --auto : key type is determined from file.
## * key-file :  key file to use.  If it contains multiple public keys, the first `rsa` key found is used.
## # OUTPUT
## Encrypted data
  spk_crypt --encrypt "$@"
}

spk_decrypt() {
## Decrypt `stdin` using a `ssh` public/private key.
## # USAGE
##     spk_decrypt [--base64] [--passwd=xxxx] [--public|--private|--auto] <key-file>
## # ARGS
## * --base64 : if specified, data will be base64 encoded.
## * --passwd=xxxx : password for encrypted private key (if any)
## * --public : use public key
## * --private : use private key
## * --auto : key type is determined from file.
## * key-file :  key file to use.  If it contains multiple public keys, the first `rsa` key found is used.
## # OUTPUT
## Encrypted data
  spk_crypt --decrypt "$@"
}

