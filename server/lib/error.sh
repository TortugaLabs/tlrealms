#
# Fatal error handler
#
fatal() {
    echo "$@" 1>&2
    exit 1
}

