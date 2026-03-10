APP        = SPCOutlook
BUNDLE     = $(APP).app
BINARY     = .build/release/$(APP)
INSTALL_TO = $(HOME)/Applications

.PHONY: build bundle install run clean

## Compile a release binary (fastest for running directly)
build:
	swift build -c release 2>&1

## Package the binary into a proper .app bundle
bundle: build
	@echo "→ Bundling $(BUNDLE)…"
	@rm -rf $(BUNDLE)
	@mkdir -p $(BUNDLE)/Contents/MacOS
	@mkdir -p $(BUNDLE)/Contents/Resources
	@cp $(BINARY)             $(BUNDLE)/Contents/MacOS/$(APP)
	@cp Supporting/Info.plist $(BUNDLE)/Contents/Info.plist
	@# Ad-hoc code sign so Gatekeeper doesn't block it
	@codesign --sign - --force $(BUNDLE)
	@echo "✓ $(BUNDLE) ready"

## Build, bundle, copy to ~/Applications, and launch
install: bundle
	@echo "→ Installing to $(INSTALL_TO)/$(BUNDLE)…"
	@rm -rf "$(INSTALL_TO)/$(BUNDLE)"
	@mkdir -p "$(INSTALL_TO)"
	@cp -r $(BUNDLE) "$(INSTALL_TO)/"
	@echo "✓ Installed"
	@open "$(INSTALL_TO)/$(BUNDLE)"
	@echo "✓ Launched — the widget should appear in the top-right of your desktop."

## Run the binary directly (no bundle, good for quick testing)
run: build
	$(BINARY)

## Remove build artifacts and bundle
clean:
	swift package clean
	rm -rf $(BUNDLE)
