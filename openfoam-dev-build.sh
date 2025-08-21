#!/usr/bin/env bash
# Minimal OpenFOAM-dev + ThirdParty-dev build script
# Edit NJOBS if you want a different parallelism
set -euo pipefail

# Config
FOAM_INST_DIR="$HOME/OpenFOAM"
FOAM_RUN="${FOAM_INST_DIR}/run"          # where cases / tutorials go
OPENFOAM_REPO="https://github.com/OpenFOAM/OpenFOAM-dev.git"
THIRD_REPO="https://github.com/OpenFOAM/ThirdParty-dev.git"
NJOBS="${NJOBS:-8}"             # override with env NJOBS
LOGDIR="$HOME/openfoam-dev-build-logs"

# MPI selection policy:
# - If USE_LOCAL_MPI=1 or FORCE_LOCAL_MPI=1 is set, prefer $HOME/local MPI.
# - Otherwise, if the environment provides the `module` command, try to find
#   and load a system MPI module (openmpi, mpi, mvapich2, impi) and prefer that.
# - If no module is found, fall back to $HOME/local.
USE_LOCAL_MPI="${USE_LOCAL_MPI:-0}"
FORCE_LOCAL_MPI="${FORCE_LOCAL_MPI:-0}"

MPI_FROM_MODULE=0
if [ "${USE_LOCAL_MPI}" != "1" ] && [ "${FORCE_LOCAL_MPI}" != "1" ] && command -v module >/dev/null 2>&1; then
  # Make personal modulefiles visible (if any)
  module use "$HOME/.modules" >/dev/null 2>&1 || true

  # Try common MPI module names in order of preference
  for m in openmpi mpi mvapich2 impi; do
    if module avail "$m" 2>&1 | grep -iq "$m"; then
      echo "[build] Loading site MPI module matching: $m"
      module load "$m" >/dev/null 2>&1 || module load "${m}" || true
      MPI_FROM_MODULE=1
      break
    fi
  done
fi

if [ "${USE_LOCAL_MPI}" = "1" ] || [ "${FORCE_LOCAL_MPI}" = "1" ] || [ "$MPI_FROM_MODULE" -eq 0 ]; then
  echo "[build] Using MPI from: $HOME/local (exporting PATH/LD_LIBRARY_PATH)." 
  export PATH="$HOME/local/bin:$PATH"
  export LD_LIBRARY_PATH="$HOME/local/lib:${LD_LIBRARY_PATH:-}"
else
  echo "[build] Using MPI provided by module. Ensure this matches compute-node MPI if running on the cluster."
fi

mkdir -p "$FOAM_INST_DIR" "$LOGDIR" "$FOAM_RUN"
cd "$FOAM_INST_DIR"

# Optionally add OpenFOAM sourcing to the user's bashrc in an idempotent way.
# Set UPDATE_BASHRC=1 when running the script to enable this.
UPDATE_BASHRC="${UPDATE_BASHRC:-0}"
BASHRC="${BASHRC:-$HOME/.bashrc}"
if [ "$UPDATE_BASHRC" = "1" ]; then
  echo "[build] Ensuring OpenFOAM sourcing block exists in: $BASHRC"
  marker_start="# >>> OpenFOAM-dev environment >>>"
  if ! grep -Fq "$marker_start" "$BASHRC" 2>/dev/null; then
    cat >> "$BASHRC" <<'EOF'
# >>> OpenFOAM-dev environment >>>
# Make personal modulefiles visible (useful on clusters using Lmod)
if command -v module >/dev/null 2>&1; then
  module use "$HOME/.modules" || true
fi

# Source OpenFOAM environment if present
if [ -f "$HOME/OpenFOAM/OpenFOAM-dev/etc/bashrc" ]; then
  . "$HOME/OpenFOAM/OpenFOAM-dev/etc/bashrc"
fi
# <<< OpenFOAM-dev environment <<<
EOF
    echo "[build] Appended OpenFOAM sourcing to $BASHRC"
  else
    echo "[build] $BASHRC already contains OpenFOAM sourcing block; skipping"
  fi
fi

# Clone if needed
if [ ! -d "$FOAM_INST_DIR/OpenFOAM-dev" ]; then
  git clone --depth 1 "$OPENFOAM_REPO" OpenFOAM-dev 2>&1 | tee "$LOGDIR/clone-openfoam.log"
fi
if [ ! -d "$FOAM_INST_DIR/ThirdParty-dev" ]; then
  git clone --depth 1 "$THIRD_REPO" ThirdParty-dev 2>&1 | tee "$LOGDIR/clone-thirdparty.log"
fi

# Make sure modulefiles dir is visible if you use modules
if command -v module >/dev/null 2>&1; then
  module use "$HOME/.modules" || true
fi

# Run builds inside isolated bash subshells that source the OpenFOAM bashrc
# This prevents the sourced file from calling `exit` or otherwise terminating
# the main script. The subshell will inherit exported env vars (PATH, LD_LIBRARY_PATH).
echo "[build] Running builds in isolated subshells (logs -> $LOGDIR)"

# ThirdParty build
THIRD_CMD='source "'"$FOAM_INST_DIR"'/OpenFOAM-dev/etc/bashrc" >/dev/null 2>&1 || true; '
THIRD_CMD+='cd "'"$FOAM_INST_DIR"'/ThirdParty-dev" && '
THIRD_CMD+='./Allwmake -j "'"$NJOBS"'"'

echo "[build] Executing ThirdParty build in subshell"
set +e
bash -lc "$THIRD_CMD" &> "$LOGDIR/thirdparty-allwmake.log"
status=$?
set -e
echo "[build] ThirdParty build log (first 200 lines):"
sed -n '1,200p' "$LOGDIR/thirdparty-allwmake.log" || true
if [ $status -ne 0 ]; then
  echo "[build][error] ThirdParty Allwmake failed with exit code $status; see $LOGDIR/thirdparty-allwmake.log"
  exit $status
fi

# OpenFOAM build
OPEN_CMD='source "'"$FOAM_INST_DIR"'/OpenFOAM-dev/etc/bashrc" >/dev/null 2>&1 || true; '
OPEN_CMD+='cd "'"$FOAM_INST_DIR"'/OpenFOAM-dev" && '
OPEN_CMD+='./Allwmake -j "'"$NJOBS"'"'

echo "[build] Executing OpenFOAM build in subshell"
set +e
bash -lc "$OPEN_CMD" &> "$LOGDIR/openfoam-allwmake.log"
status=$?
set -e
echo "[build] OpenFOAM build log (first 200 lines):"
sed -n '1,200p' "$LOGDIR/openfoam-allwmake.log" || true
if [ $status -ne 0 ]; then
  echo "[build][error] OpenFOAM Allwmake failed with exit code $status; see $LOGDIR/openfoam-allwmake.log"
  exit $status
fi
echo "Build logs in $LOGDIR"
