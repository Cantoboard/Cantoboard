#!/bin/sh

BUILD_DIR=build

if [ -z "$LIBRIME_ROOT" ]; then
echo "Please set LIBRIME_ROOT to point to the librime dir."
exit 0
fi

mkdir build || true

LIB_NAME=Rime
DYLIBS="$LIBRIME_ROOT/dist/lib/librime.1.7.3.dylib"
SOURCE_INFO_PLIST="src/Info.plist"
OUT_DIR=$BUILD_DIR

# set OUT_DIR and LIB_NAME
FW_PATH="$OUT_DIR/$LIB_NAME.framework"
INFO_PLIST="$FW_PATH/Info.plist"
OUT_DYLIB="$FW_PATH/$LIB_NAME"

# set the DYLIBS and SOURCE_INFO_PLIST for the library
mkdir -p "$FW_PATH"
cp "$SOURCE_INFO_PLIST" "$INFO_PLIST"
lipo $DYLIBS -output "$OUT_DYLIB" -create
install_name_tool -id @rpath/$LIB_NAME.framework/$LIB_NAME "$OUT_DYLIB"

# set the DYLIBS and SOURCE_INFO_PLIST for DSYM
dsymutil "$OUT_DYLIB" --out "$FW_PATH.dSYM"

# Convert Framework to XCFramework
rm -rf "$OUT_DIR/iphoneos" || true
rm -rf "$OUT_DIR/iphonesimulator" || true
mkdir -p "$OUT_DIR/iphoneos"
mkdir -p "$OUT_DIR/iphonesimulator"

IPHONE_OS_FW_PATH="$OUT_DIR/iphoneos/$LIB_NAME.framework"
IPHONE_SIM_FW_PATH="$OUT_DIR/iphonesimulator/$LIB_NAME.framework"

cp -R $FW_PATH "$IPHONE_OS_FW_PATH"
cp -R $FW_PATH "$IPHONE_SIM_FW_PATH"

IPHONE_OS_FW_LIB_PATH="$IPHONE_OS_FW_PATH/$LIB_NAME"
IPHONE_SIM_FW_LIB_PATH="$IPHONE_SIM_FW_PATH/$LIB_NAME"

echo "Spliting fat libs..."
xcrun lipo -remove x86_64 "$IPHONE_OS_FW_LIB_PATH" -o "$IPHONE_OS_FW_LIB_PATH"
xcrun lipo -remove arm64 "$IPHONE_SIM_FW_LIB_PATH" -o "$IPHONE_SIM_FW_LIB_PATH"

echo "Creating XCFramework..."
XCFW_PATH="$BUILD_DIR/$LIB_NAME.xcframework"
xcodebuild -create-xcframework -framework "$IPHONE_OS_FW_PATH"/ -framework "$IPHONE_SIM_FW_PATH"/ -output "$XCFW_PATH"
