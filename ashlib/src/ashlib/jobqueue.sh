#!/bin/sh
#
# Based on [A Job Queue in BASH](https://hackthology.com/a-job-queue-in-bash.html)
# by Tim Henderson (February 2017)
#


job_worker() {
  ## This is the worker thread function

  local id="$1" ; shift

  # first open the file and locks for reading...
  exec 3<$fifo
  exec 4<$fifo_lock
  exec 5<$start_lock

  # notify parent that worker is ready...
  flock 5		# obtains tart lock
  echo $id >> $start	# put my worker id in start file
  flock -u 5		# release lock
  exec 5<&-		# close lock file
  $verbose worker $id ready

  while true
  do
    # read queue
    flock 4				# obtain fifo lock
    read -su 3 work_id work_item	# read work-id and item...
    local read_status=$?		# save the exit status...
    flock -u 4				# release fifo lock

    if [ $read_status -eq 0 ] ; then
      # Valid work item... execute
      $verbose $id got work_id=$work_id work_item=$work_item 1>&2
      # run job in subshell...
      ( "$@" "$work_id" "$work_item" )
    else
      # anything else is EOF
      break
    fi
  done
  # clean-up fds
  exec 3<&-
  exec 4<&-
  $verbose $id "done working" 1>&2
}

job_queue() {
  ## Run jobs in a queue
  ## # USAGE
  ##   <job generator> | job_queue [--workers=n] job_cmd [args]
  ## # OPTIONS
  ## * --workers=n -- number of worker threads (defaults to 4)
  ## * --verbose : output messages
  ## * job_cmd -- command to execute
  ## * args -- optional arguments
  ## # RETURNS
  ## 1 on error
  ## # DESC
  ##

  local workers=4 verbose=:

  while [ $# -gt 0 ]
  do
    case "$1" in
    --workers=*)
      workers=${1#--workers=}
      ;;
    --verbose)
      verbose=echo
      ;;
    *)
      break
      ;;
    esac
    shift
  done
  if [ -z "$workers" ] ; then
    echo "No workers specified" 1>&2
    return 1
  fi
  if [ "$workers" -lt 1 ] ; then
    echo "Must specify at least 1 worker ($workers)" 1>&2
    return 2
  fi
  if [ $# -eq 0 ] ; then
    echo "No job command specified" 1>&2
    return 3
  fi

  # make the IPC files
  local ipcd=$(mktemp -d)
  local start=$ipcd/start ; > $start
  local fifo=$ipcd/fifo ; mkfifo $fifo

  local fifo_lock=$ipcd/fifo.lock ; > $fifo_lock
  local start_lock=$ipcd/start.lock ; > $start_lock

  local rc=0
  (
    local i=0
    while [ $i -lt $workers ]
    do
      $verbose Starting $i 1>&2
      job_worker $i "$@" &
      i=$(expr $i + 1)
    done


    exec 3> $fifo			# Open fifo for writing
    exec 4< $start_lock		# open the start lock for reading

    # Wating for workers to start
    while true
    do
      flock 4
      local started=$(wc -l $start | cut -d ' ' -f 1)
      flock -u 4
      if [ $started -ew $workers ] ; then
	break
      else
	$verbose waiting, $started of $workers
      fi
    done
    exec 4<&- # Close start lock

    # Produce the jobs to run...
    local ln i=0
    while read ln
    do
      i=$(expr $i + 1)
      $verbose sending $i $ln 1>&2
      echo $i $ln 1>&3 ## send item to fd3
    done

    exec 3<&- # close the fifo
    wait # Wait for all the workers
  ) || rc=$?
  rm -rf $ipcd
  return $rc
}



