#!/bin/bash
# Packages the Linux release bundle into artifacts/linux_package/
# Mirrors exactly the "Create Linux installation package" CI step.
# Must be run from the ScrcpyGui/ directory.
set -euo pipefail

APP_NAME="scrcpy_gui_prod"
BUILD_PATH="build/linux/x64/release/bundle"

if [ ! -d "$BUILD_PATH" ]; then
  echo "Error: release bundle not found at $BUILD_PATH" >&2
  echo "Run 'flutter build linux --release' first." >&2
  exit 1
fi

# Create package directory
rm -rf linux_package
mkdir -p linux_package

# Copy the entire bundle
cp -r "${BUILD_PATH}" "linux_package/${APP_NAME}"

# Create desktop entry file
cat > "linux_package/${APP_NAME}.desktop" << 'DESKTOP_EOF'
[Desktop Entry]
Name=Scrcpy GUI
Comment=A GUI for Scrcpy - Android screen mirroring
Exec=scrcpy_gui_prod
Icon=scrcpy_gui_prod
Terminal=false
Type=Application
Categories=Utility;
DESKTOP_EOF

# Create install script
cat > linux_package/install.sh << 'INSTALL_EOF'
#!/bin/bash

# Linux App Installer for scrcpy_gui_prod
# This script installs the app and creates desktop integration

set -e

APP_NAME="scrcpy_gui_prod"
INSTALL_DIR="$HOME/.local/share/${APP_NAME}"
BIN_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons/hicolor/256x256/apps"

echo "======================================"
echo "  Linux App Installer"
echo "======================================"
echo ""

# Check if app bundle exists
if [ ! -d "$APP_NAME" ]; then
    echo "Error: $APP_NAME directory not found"
    echo "Please run this script from the extracted folder"
    exit 1
fi

# Check for required dependencies
echo "Step 1: Checking dependencies..."
if ! dpkg -l | grep -q libgtk-3-0; then
    echo "Warning: libgtk-3-0 not found. Installing..."
    echo "You may need to enter your password:"
    sudo apt-get update
    sudo apt-get install -y libgtk-3-0
fi
echo "✓ Dependencies satisfied"
echo ""

# Create directories
echo "Step 2: Creating directories..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"
mkdir -p "$DESKTOP_DIR"
mkdir -p "$ICON_DIR"
echo "✓ Directories created"
echo ""

# Copy application files
echo "Step 3: Installing application..."
if [ -d "$INSTALL_DIR/$APP_NAME" ]; then
    echo "Removing old installation..."
    rm -rf "$INSTALL_DIR/$APP_NAME"
fi
cp -r "$APP_NAME" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/${APP_NAME}/${APP_NAME}"
echo "✓ Application installed to $INSTALL_DIR"
echo ""

# Create symlink in bin directory
echo "Step 4: Creating launcher..."
ln -sf "$INSTALL_DIR/${APP_NAME}/${APP_NAME}" "$BIN_DIR/${APP_NAME}"
echo "✓ Launcher created in $BIN_DIR"
echo ""

# Install icon if it exists
echo "Step 5: Installing icon..."
if [ -f "$APP_NAME/data/flutter_assets/icon.png" ]; then
    cp "$APP_NAME/data/flutter_assets/icon.png" "$ICON_DIR/${APP_NAME}.png"
    echo "✓ Icon installed"
else
    echo "⚠ Icon not found, skipping"
fi
echo ""

# Install desktop entry
echo "Step 6: Creating desktop entry..."
cat > "$DESKTOP_DIR/${APP_NAME}.desktop" << DESKTOP_EOF
[Desktop Entry]
Name=Scrcpy GUI
Comment=A GUI for Scrcpy - Android screen mirroring
Exec=$BIN_DIR/${APP_NAME}
Icon=${APP_NAME}
Terminal=false
Type=Application
Categories=Utility;
DESKTOP_EOF

chmod +x "$DESKTOP_DIR/${APP_NAME}.desktop"
echo "✓ Desktop entry created"
echo ""

# Update desktop database
echo "Step 7: Updating desktop database..."
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
fi
echo "✓ Database updated"
echo ""

echo "======================================"
echo "  Installation Complete!"
echo "======================================"
echo ""
echo "The app has been installed to:"
echo "  $INSTALL_DIR"
echo ""
echo "You can now run it by:"
echo "  - Searching for 'Scrcpy GUI' in your application menu"
echo "  - Running: $APP_NAME"
echo "  - Running: $BIN_DIR/${APP_NAME}"
echo ""
echo "To uninstall, run: ./uninstall.sh"
echo ""
INSTALL_EOF

# Make install script executable
chmod +x linux_package/install.sh

# Create uninstall script
cat > linux_package/uninstall.sh << 'UNINSTALL_EOF'
#!/bin/bash

# Uninstaller for scrcpy_gui_prod

APP_NAME="scrcpy_gui_prod"
INSTALL_DIR="$HOME/.local/share/${APP_NAME}"
BIN_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons/hicolor/256x256/apps"

echo "======================================"
echo "  Uninstalling Scrcpy GUI"
echo "======================================"
echo ""

# Remove application files
if [ -d "$INSTALL_DIR" ]; then
    echo "Removing application files..."
    rm -rf "$INSTALL_DIR"
    echo "✓ Application files removed"
fi

# Remove symlink
if [ -L "$BIN_DIR/${APP_NAME}" ]; then
    echo "Removing launcher..."
    rm "$BIN_DIR/${APP_NAME}"
    echo "✓ Launcher removed"
fi

# Remove desktop entry
if [ -f "$DESKTOP_DIR/${APP_NAME}.desktop" ]; then
    echo "Removing desktop entry..."
    rm "$DESKTOP_DIR/${APP_NAME}.desktop"
    echo "✓ Desktop entry removed"
fi

# Remove icon
if [ -f "$ICON_DIR/${APP_NAME}.png" ]; then
    echo "Removing icon..."
    rm "$ICON_DIR/${APP_NAME}.png"
    echo "✓ Icon removed"
fi

# Update desktop database
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
fi

echo ""
echo "======================================"
echo "  Uninstall Complete!"
echo "======================================"
echo ""
UNINSTALL_EOF

# Make uninstall script executable
chmod +x linux_package/uninstall.sh

# Create README
cat > linux_package/README.txt << 'README_EOF'
Linux Installation Instructions
=================================

EASY INSTALLATION (Recommended):
---------------------------------
1. Open Terminal in this directory
2. Run: chmod +x install.sh
3. Run: ./install.sh
4. The app will be installed and available in your application menu!

ALTERNATIVE - One-line installation:
------------------------------------
Copy and paste this into Terminal:

chmod +x install.sh && ./install.sh

MANUAL INSTALLATION:
--------------------
1. Extract the scrcpy_gui_prod folder to your desired location
2. Run: chmod +x scrcpy_gui_prod/scrcpy_gui_prod
3. Run: ./scrcpy_gui_prod/scrcpy_gui_prod

UNINSTALLATION:
---------------
Run: ./uninstall.sh

REQUIREMENTS:
-------------
- GTK3 libraries (usually pre-installed)
- If missing, install with: sudo apt-get install libgtk-3-0

WHAT DOES THE INSTALLER DO?
----------------------------
- Installs the app to ~/.local/share/scrcpy_gui_prod
- Creates a launcher in ~/.local/bin/scrcpy_gui_prod
- Adds desktop entry for application menu integration
- Installs the application icon
- Checks and installs required dependencies

TROUBLESHOOTING:
----------------
If the app doesn't appear in your menu after installation:
- Log out and log back in
- Or run: update-desktop-database ~/.local/share/applications

If you get permission errors:
- Make sure the install.sh script is executable
- Some distributions may require different installation paths
README_EOF

# Move to artifacts directory
rm -rf artifacts/linux_package
mkdir -p artifacts
mv linux_package artifacts/

# Show package contents
echo "Package contents:"
ls -lh artifacts/linux_package/
