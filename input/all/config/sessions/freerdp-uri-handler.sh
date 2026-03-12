#!/bin/bash
# URI handler for xfreerdp:// links
# Called by Chromium when user clicks an xfreerdp:// link
#
# URI format: xfreerdp://host[:port][?user=USER&smartcard=1]
#
# Example: xfreerdp://rdphost.example.com?smartcard=1

URI="$1"

if [ -z "$URI" ]; then
    echo "Usage: $0 xfreerdp://host[:port][?user=USER&smartcard=1]"
    exit 1
fi

# Strip scheme
STRIPPED="${URI#xfreerdp://}"

# Split host and query string
HOST="${STRIPPED%%\?*}"
QUERY="${STRIPPED#*\?}"

# Parse query params
RDP_USER=""
USE_SMARTCARD=0
RDP_PORT=3389

if [ "$QUERY" != "$STRIPPED" ]; then
    IFS='&' read -ra PARAMS <<< "$QUERY"
    for param in "${PARAMS[@]}"; do
        key="${param%%=*}"
        val="${param#*=}"
        case "$key" in
            user)       RDP_USER="$val" ;;
            smartcard)  USE_SMARTCARD="$val" ;;
            port)       RDP_PORT="$val" ;;
        esac
    done
fi

# Build xfreerdp command
ARGS=(
    /v:"${HOST}:${RDP_PORT}"
    /cert:tofu
    /dynamic-resolution
    +clipboard
    /audio-mode:0
    /rfx
)

if [ "$USE_SMARTCARD" = "1" ]; then
    ARGS+=(/smartcard)
fi

if [ -n "$RDP_USER" ]; then
    ARGS+=(/u:"$RDP_USER")
fi

exec /opt/freerdp/bin/xfreerdp "${ARGS[@]}"
