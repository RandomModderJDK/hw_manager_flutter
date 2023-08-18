#!/bin/bash

set -e

command -v realpath >/dev/null 2>&1 || realpath() {
	[[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

usage() {
	echo "usage: $0 inputXcarchive outputPath"
	echo "  inputXcarchive is path to e.g. UTM.xcarchive"
	echo "  outputPath is path to an EMPTY output directory for e.g. UTM.ipa"
	exit 1
}

if [ $# -lt 2 ]; then
	usage
fi

INPUT=$1
OUTPUT=$2

INPUT_APP="$INPUT/Products/Applications/Runner.app"
echo "$(/usr/libexec/PlistBuddy "$INPUT_APP/Info.plist")"
NAME=$(/usr/libexec/PlistBuddy -c "Print :CFBundleName" "$INPUT_APP/Info.plist")
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INPUT_APP/Info.plist")

if [ ! -d "$INPUT_APP" ]; then
	echo "Invalid xcarchive input!"
	usage
fi

if [ -z "$OUTPUT" ]; then
	echo "Invalid output path"
	usage
fi

fake_sign() {
	local _name=$1
	local _bundle_id=$2
	local _input=$3
	local _output=$4
	local _fakeent=$5

	mkdir -p "$_output"
	cp -a "$_input" "$_output/"
	find "$_output" -type d -path '*/Frameworks/*.framework' -exec ldid -S \{\} \;
	echo "ldid -S${_fakeent} -I${_bundle_id} "${_output}/Applications/Runner.app/Runner""
	ldid -S${_fakeent} -I${_bundle_id} "$_output/Applications/Runner.app/Runner"
}

create_fake_ipa() {
	local NAME=$1
	local BUNDLE_ID=$2
	local INPUT=$3
	local OUTPUT=$4
	local FAKEENT=$5

	pwd="$(pwd)"
	mkdir -p "$OUTPUT"
	rm -rf "$OUTPUT/Applications" "$OUTPUT/Payload" "$OUTPUT/$NAME.ipa"
	fake_sign "$NAME" "$BUNDLE_ID" "$INPUT/Products/Applications" "$OUTPUT" "$FAKEENT"
	mv "$OUTPUT/Applications" "$OUTPUT/Payload"
	cd "$OUTPUT"
	zip -r "$NAME.ipa" "Payload" -x "._*" -x ".DS_Store" -x "__MACOSX"
	rm -r "Payload"
	cd "$pwd"
	echo "IPA at $OUTPUT/$NAME.ipa"
}

FAKEENT="/tmp/fakeent.$$.plist"
cat >"$FAKEENT" <<EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>get-task-allow</key>
	<true/>
	<key>com.apple.developer.kernel.increased-memory-limit</key>
	<true/>
	<key>com.apple.developer.kernel.extended-virtual-addressing</key>
	<true/>
	<key>dynamic-codesigning</key>
	<true/>
	<key>com.apple.private.iokit.IOServiceSetAuthorizationID</key>
	<true/>
	<key>com.apple.security.exception.iokit-user-client-class</key>
	<array>
		<string>AppleUSBHostDeviceUserClient</string>
		<string>AppleUSBHostInterfaceUserClient</string>
	</array>
	<key>com.apple.system.diagnostics.iokit-properties</key>
	<true/>
	<key>com.apple.vm.device-access</key>
	<true/>
	<key>com.apple.private.hypervisor</key>
	<true/>
	<key>com.apple.private.memorystatus</key>
	<true/>
</dict>
</plist>
EOL
create_fake_ipa "$NAME" "$BUNDLE_ID" "$INPUT" "$OUTPUT" "$FAKEENT"
rm "$FAKEENT"

