#!/usr/bin/bash
set -euo pipefail

: "${VG_NAME:?VG_NAME must be set}"
: "${PV_DEV:?PV_DEV must be set}"
: "${NODE_NAME:=unknown}"

: "${METRICS_ENABLED:=1}"
: "${METRICS_DIR:=/var/lib/node_exporter}"
: "${METRICS_FILE:=lvm_diskprep.prom}"
: "${INTERVAL_SECONDS:=120}"

umask 022

ns() { nsenter -t 1 -m -u -i -n -p -- "$@"; }

write_metrics() {
  [ "$METRICS_ENABLED" = "1" ] || return 0

  TMP="${METRICS_DIR}/${METRICS_FILE}.$$"
  FINAL="${METRICS_DIR}/${METRICS_FILE}"

  VG_PRESENT=0
  PV_PRESENT=0
  VG_FREE_BYTES=0
  VG_SIZE_BYTES=0
  REASON="none"

  if [ ! -b "$PV_DEV" ]; then
    REASON="pv_device_missing"
  else
    if ns pvs "$PV_DEV" >/dev/null 2>&1; then
      PV_PRESENT=1
    fi

    if ns vgs "$VG_NAME" >/dev/null 2>&1; then
      VG_PRESENT=1
      VG_FREE_BYTES="$(ns vgs "$VG_NAME" --noheadings --units b --nosuffix -o vg_free 2>/dev/null | tr -d ' ' || echo 0)"
      VG_SIZE_BYTES="$(ns vgs "$VG_NAME" --noheadings --units b --nosuffix -o vg_size 2>/dev/null | tr -d ' ' || echo 0)"
    fi
  fi

  mkdir -p "$METRICS_DIR"

  cat > "$TMP" <<EOF
# HELP lvm_diskprep_vg_present 1 if VG exists on node
# TYPE lvm_diskprep_vg_present gauge
lvm_diskprep_vg_present{node="${NODE_NAME}",vg="${VG_NAME}"} ${VG_PRESENT}
# HELP lvm_diskprep_pv_present 1 if PV exists on node device
# TYPE lvm_diskprep_pv_present gauge
lvm_diskprep_pv_present{node="${NODE_NAME}",device="${PV_DEV}"} ${PV_PRESENT}
# HELP lvm_diskprep_vg_free_bytes Free bytes in VG
# TYPE lvm_diskprep_vg_free_bytes gauge
lvm_diskprep_vg_free_bytes{node="${NODE_NAME}",vg="${VG_NAME}"} ${VG_FREE_BYTES}
# HELP lvm_diskprep_vg_size_bytes Total size bytes in VG
# TYPE lvm_diskprep_vg_size_bytes gauge
lvm_diskprep_vg_size_bytes{node="${NODE_NAME}",vg="${VG_NAME}"} ${VG_SIZE_BYTES}
# HELP lvm_diskprep_status 1 always; reason label explains last observed state
# TYPE lvm_diskprep_status gauge
lvm_diskprep_status{node="${NODE_NAME}",reason="${REASON}"} 1
EOF

  mv "$TMP" "$FINAL"
  chmod 0644 "$FINAL" || true
}

ensure_lvm() {
  if [ ! -b "$PV_DEV" ]; then
    echo "ERROR: PV device not found: $PV_DEV"
    ls -l /dev/disk/by-partlabel || true
    return 1
  fi

  if ns vgs "$VG_NAME" >/dev/null 2>&1; then
    echo "VG ${VG_NAME} already exists (no-op)."
    return 0
  fi

  if ns pvs "$PV_DEV" >/dev/null 2>&1; then
    echo "PV already present on ${PV_DEV}."
  else
    echo "Creating PV on ${PV_DEV}."
    ns pvcreate -y "$PV_DEV"
  fi

  echo "Creating VG ${VG_NAME} on ${PV_DEV}."
  ns vgcreate "$VG_NAME" "$PV_DEV"
}

while true; do
  if ensure_lvm; then
    echo "LVM ensure: OK"
  else
    echo "LVM ensure: FAILED"
  fi

  write_metrics || true
  sleep "$INTERVAL_SECONDS"
done
