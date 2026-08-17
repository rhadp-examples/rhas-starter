#!/bin/bash
set -e

SWTPM_PID=""
MAIN_PID=""

cleanup() {
  if [ -n "$SWTPM_PID" ] && kill -0 "$SWTPM_PID" 2>/dev/null; then
    kill "$SWTPM_PID" 2>/dev/null
    wait "$SWTPM_PID" 2>/dev/null
  fi
}
trap cleanup EXIT

# Forward termination signals (e.g. from `kubectl delete pod`/kubelet) to the
# supervised main process and swtpm so both shut down cleanly instead of
# being left running as orphans of this script.
forward_signal() {
  [ -n "$MAIN_PID" ] && kill -TERM "$MAIN_PID" 2>/dev/null
  [ -n "$SWTPM_PID" ] && kill -TERM "$SWTPM_PID" 2>/dev/null
}
trap forward_signal TERM INT

swtpm socket \
  --tpmstate dir=/tmp/swtpm \
  --tpm2 \
  --ctrl type=tcp,port=2322 \
  --server type=tcp,port=2321 \
  --flags not-need-init &
SWTPM_PID=$!

export TPM2TOOLS_TCTI="swtpm:host=127.0.0.1,port=2321"

# 100 * 0.1s = 10s startup budget; also bail out early if swtpm itself died
# instead of just timing out.
timeout=100
while ! nc -z 127.0.0.1 2321 2>/dev/null; do
  if ! kill -0 "$SWTPM_PID" 2>/dev/null; then
    echo "ERROR: swtpm process exited unexpectedly" >&2
    exit 1
  fi
  sleep 0.1
  timeout=$((timeout - 1))
  if [ "$timeout" -le 0 ]; then
    echo "ERROR: swtpm failed to start within 10s" >&2
    exit 1
  fi
done

tpm2_startup -c

# Run the main command as a supervised child (instead of exec'ing over this
# script) so swtpm is reliably stopped and reaped via the cleanup trap once
# the main process exits, rather than being orphaned as PID 1's problem.
"$@" &
MAIN_PID=$!
wait "$MAIN_PID"
exit_code=$?
exit "$exit_code"
