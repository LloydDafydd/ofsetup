#!/usr/bin/env bash
# Stage 2: run builds after cloning and sourcing
set -euo pipefail

# Config (can be overridden by env)
NJOBS="${NJOBS:-8}"
FOAM_INST_DIR="${FOAM_INST_DIR:-$HOME/OpenFOAM}"
LOGDIR="${LOGDIR:-$HOME/openfoam-dev-build-logs}"

mkdir -p "$LOGDIR"

echo "[stage2] FOAM_INST_DIR=$FOAM_INST_DIR NJOBS=$NJOBS LOGDIR=$LOGDIR"

# Source OpenFOAM environment safely (turn off nounset while sourcing)
set +u
export ZSH_NAME=""
if [ -f "$FOAM_INST_DIR/OpenFOAM-dev/etc/bashrc" ]; then
  # Source and let the bashrc handle its own checks
  source "$FOAM_INST_DIR/OpenFOAM-dev/etc/bashrc"
else
  echo "[stage2][error] OpenFOAM bashrc not found: $FOAM_INST_DIR/OpenFOAM-dev/etc/bashrc"
  exit 1
fi
set -u

# Helper to run a build step
run_build() {
  local dir="$1"; shift
  local logfile="$1"; shift
  if [ ! -d "$dir" ]; then
    echo "[stage2][error] Directory not found: $dir"; return 2
  fi
  cd "$dir"
  echo "[stage2] In $(pwd)"
  if [ ! -f ./Allwmake ]; then
    echo "[stage2][error] ./Allwmake missing in $(pwd)"; return 3
  fi
  chmod +x ./Allwmake || true
  echo "[stage2] Running Allwmake (logs -> $logfile)"
  set +e
  ./Allwmake -j "$NJOBS" &> "$logfile"
  local rc=$?
  set -e
  echo "[stage2] Completed with exit code $rc; tail of log:"
  tail -n 50 "$logfile" || true
  return $rc
}

run_build "$FOAM_INST_DIR/ThirdParty-dev" "$LOGDIR/thirdparty-allwmake.log"
rc=$?
if [ $rc -ne 0 ]; then
  echo "[stage2][error] ThirdParty build failed (rc=$rc). See $LOGDIR/thirdparty-allwmake.log"
  exit $rc
fi

run_build "$FOAM_INST_DIR/OpenFOAM-dev" "$LOGDIR/openfoam-allwmake.log"
rc=$?
if [ $rc -ne 0 ]; then
  echo "[stage2][error] OpenFOAM build failed (rc=$rc). See $LOGDIR/openfoam-allwmake.log"
  exit $rc
fi

echo "[stage2] Build finished successfully. Logs in $LOGDIR"
