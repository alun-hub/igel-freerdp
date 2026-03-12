#!/bin/bash
set -e

# Symlink xfreerdp so it's in PATH
ln -sf /opt/freerdp/bin/xfreerdp /usr/local/bin/xfreerdp

# Symlink shared libs so the dynamic linker finds them
FREERDP_LIB=/opt/freerdp/lib
for lib in "$FREERDP_LIB"/*.so*; do
    base=$(basename "$lib")
    ln -sf "$lib" "/usr/local/lib/$base"
done
ldconfig

# Register xfreerdp:// URI handler via .desktop file
cat > /usr/share/applications/xfreerdp.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=FreeRDP
Exec=/usr/local/bin/xfreerdp-uri-handler %u
MimeType=x-scheme-handler/xfreerdp;
NoDisplay=true
EOF

update-desktop-database /usr/share/applications || true
