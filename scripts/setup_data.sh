#!/usr/bin/env bash
# scripts/setup_data.sh
# Idempotent: downloads Pokemon.csv into data/raw/ if it's not already there.
# Falls back to a public GitHub mirror so we don't need a Kaggle account.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
RAW_DIR="${ROOT_DIR}/data/raw"
TARGET="${RAW_DIR}/Pokemon.csv"

# Public mirror of the Kaggle dataset abcsds/pokemon (same content, no auth required)
MIRROR_URL="https://gist.githubusercontent.com/armgilles/194bcff35001e7eb53a2a8b441e8b2c6/raw/92200bc0a673d5ce2110aaad4544ed6c4010f687/pokemon.csv"

mkdir -p "${RAW_DIR}"

if [[ -s "${TARGET}" ]]; then
    echo "[setup_data] Pokemon.csv already exists at ${TARGET} — skipping download."
    echo "[setup_data] Rows: $(wc -l < "${TARGET}")"
    exit 0
fi

echo "[setup_data] Downloading Pokemon.csv from public mirror..."
echo "[setup_data]   URL: ${MIRROR_URL}"
curl -fSL --retry 3 --retry-delay 2 -o "${TARGET}" "${MIRROR_URL}"

echo "[setup_data] Done. File saved at ${TARGET}"
echo "[setup_data] Rows (incl. header): $(wc -l < "${TARGET}")"
echo "[setup_data] Preview:"
head -3 "${TARGET}"
