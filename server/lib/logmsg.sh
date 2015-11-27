#
# Log messages
#
logmsg() {
    logger -s -p 'user.notice' -t $(basename $0),$remhost "$*"
}
