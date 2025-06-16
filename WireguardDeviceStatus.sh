#!/bin/bash
# Author: $t@$h
# Checks status of devices on a wireguard network
# wg is great for simple embedded device transit security

INTERFACE="wg0"
THRESHOLD=120  # Time threshold in seconds
CURRENT_TIME=$(date +%s)
CRITICAL_COUNT=0
WARNING_COUNT=0
TOTAL_PEERS=0

WG_HANDSHAKES=$(wg show "$INTERFACE" latest-handshakes 2>/dev/null)

if [[ -z "$WG_HANDSHAKES" ]]; then
    echo "CRITICAL: WireGuard not running or no peers detected!"
    exit 2
fi

while read -r PEER HANDSHAKE; do
    ((TOTAL_PEERS++))

    if [[ "$HANDSHAKE" -eq 0 ]]; then
        ((CRITICAL_COUNT++))
    else
        TIME_DIFF=$((CURRENT_TIME - HANDSHAKE))
        if [[ "$TIME_DIFF" -gt "$THRESHOLD" ]]; then
            ((WARNING_COUNT++))
        fi
    fi
done <<< "$WG_HANDSHAKES"

if [[ "$CRITICAL_COUNT" -gt 0 ]]; then
    echo "CRITICAL: $CRITICAL_COUNT/$TOTAL_PEERS peers have lost handshake!"
    exit 2
elif [[ "$WARNING_COUNT" -gt 0 ]]; then
    echo "WARNING: $WARNING_COUNT/$TOTAL_PEERS peers have stale handshakes!"
    exit 1
else
    echo "OK: All $TOTAL_PEERS peers are active and handshaking."
    exit 0
fi
