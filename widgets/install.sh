#!/bin/bash
# Install SPC Outlook widget into Übersicht widgets directory

UBERSICHT_WIDGETS="$HOME/Library/Application Support/Übersicht/widgets"
WIDGET_DIR="$UBERSICHT_WIDGETS/spc-outlook"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -d "$UBERSICHT_WIDGETS" ]; then
  echo "ERROR: Übersicht widgets directory not found."
  echo "  Make sure Übersicht is installed and has been opened at least once."
  echo "  Download: https://tracesOf.net/uebersicht/"
  exit 1
fi

echo "Installing SPC Outlook widget..."
mkdir -p "$WIDGET_DIR"
cp "$SCRIPT_DIR/spc-outlook/spc-outlook.jsx" "$WIDGET_DIR/spc-outlook.jsx"

echo "Done! Widget installed to:"
echo "  $WIDGET_DIR"
echo ""
echo "Übersicht will detect the new widget automatically."
echo "If it doesn't appear, use Übersicht > Refresh All Widgets."
