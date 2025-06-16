#!/bin/bash
# $t@$h

MODULE_BASENAME="auto_hardening"
TEMP_DIR="/var/tmp/selinux_hardener"
LOG_FILE="/var/log/selinux_hardener.log"
SLEEP_DURATION=60     # Seconds between denial checks
MAX_ITERATIONS=10     # Max passes until we consider it stabilized
AUDIT_SEARCH_WINDOW=300  # Seconds of AVC logs to search per pass
CLEANUP_MODULES=true  # Set to false to keep all iterations .pp files as backup

mkdir -p "$TEMP_DIR"
touch "$LOG_FILE"
echo "SELinux Hardener started at $(date)" >> "$LOG_FILE"

# Ensure SELinux is not disabled
if [[ "$(getenforce)" == "Disabled" ]]; then
    echo "Error: SELinux is disabled. Exiting." | tee -a "$LOG_FILE"
    exit 1
fi

setenforce 0

for (( i = 1; i <= MAX_ITERATIONS; i++ )); do
    MODULE_NAME="${MODULE_BASENAME}_${i}"
    echo "Pass $i: scanning for AVC denials in the last $AUDIT_SEARCH_WINDOW seconds."

    START_TIME="$(date --date="-$AUDIT_SEARCH_WINDOW seconds" '+%Y-%m-%d %H:%M:%S')"
    cd "$TEMP_DIR"
    ausearch -m avc -ts "$START_TIME" | audit2allow -M "$MODULE_NAME" 2>>"$LOG_FILE"

    if [[ -f "${MODULE_NAME}.pp" ]]; then
        if grep -q 'allow' "${MODULE_NAME}.te"; then
            semodule -i "${MODULE_NAME}.pp"
            echo "Policy $MODULE_NAME installed." >> "$LOG_FILE"
        else
            echo "No new allow rules found in this pass." >> "$LOG_FILE"
            $CLEANUP_MODULES && rm -f "${MODULE_NAME}".{pp,te,fc,mod}
            break
        fi
    else
        echo "No new AVC denials found in this pass." >> "$LOG_FILE"
        break
    fi

    echo "Sleeping $SLEEP_DURATION seconds"
    sleep "$SLEEP_DURATION"
done

setenforce 1
echo "Hardening complete. Policies written to: $TEMP_DIR" >> "$LOG_FILE"
