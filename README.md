# FreeRDP IGEL OS 12 App Recipe

FreeRDP 3.x with smartcard (PC/SC) passthrough, packaged as an IGEL OS 12 app.

## Structure

```
igel-freerdp/
├── app.json                              # IGEL app metadata
├── build-freerdp.sh                      # Script to build FreeRDP tarball
├── igel/
│   ├── debian.json                       # Debian lib dependencies
│   ├── thirdparty.json                   # Third-party binary declaration
│   ├── install.json                      # File installation rules
│   ├── install.sh                        # Post-install (symlinks, URI handler)
│   └── pre_package_commands.sh           # Pre-packaging cleanup
├── data/
│   ├── app.png                           # Color icon (add manually)
│   └── app-mono.png                      # Monochrome icon (add manually)
└── input/all/config/sessions/
    └── freerdp-uri-handler.sh            # xfreerdp:// URI handler
```

## Build steps

### 1. Build FreeRDP tarball (Ubuntu 22.04)

```bash
chmod +x build-freerdp.sh
./build-freerdp.sh
# Produces: freerdp-3.0.0-linux64.tar.gz
cp /tmp/freerdp-3.0.0-linux64.tar.gz ./freerdp-3.x-linux64.tar.gz
```

Or use Docker to keep your system clean:

```bash
docker run --rm -v "$PWD":/out ubuntu:22.04 bash -c \
  "cd /out && ./build-freerdp.sh"
```

### 2. Add icons

Place 256x256 PNG icons in `data/`:
- `app.png` — color
- `app-mono.png` — monochrome (white on transparent)

### 3. Upload to IGEL App Creator Portal

1. Zip the entire `igel-freerdp/` directory
2. Go to https://appcreator.igel.com
3. Upload recipe ZIP
4. Upload `freerdp-3.x-linux64.tar.gz` as third-party binary
5. Build → download `.ipkg`

### 4. Deploy via UMS

1. UMS → Apps → Import `.ipkg`
2. Assign to profile/devices
3. Verify smartcard is enabled: `Security > Smartcard > Services > Activate PC/SC daemon`

## URI format

Once installed, FreeRDP sessions can be launched from Chromium via:

```
xfreerdp://rdphost.example.com?smartcard=1
xfreerdp://rdphost.example.com:3389?user=DOMAIN%5Cusername&smartcard=1
```

## Smartcard notes

- PC/SC daemon (`pcscd`) must be active in IGEL OS (default: on)
- The smartcard reader connects to the RDP host via the RDP RDPESC channel
- No extra configuration needed in the recipe — apps share the host PC/SC stack
