#!/bin/sh

BUILD_DIR=build
SRC_DIR=src

LIB_NAME=Rime
DYLIBS="$LIBRIME_ROOT/dist/lib/librime.1.7.3.dylib"
XCFW_PATH="$LIB_NAME.xcframework"

if [ -z "$LIBRIME_ROOT" ]; then
echo "Please set LIBRIME_ROOT to point to the librime dir."
exit 0
fi

rm -rf "$BUILD_DIR" || true
mkdir "$BUILD_DIR" 

FAT_FW_PATH="$BUILD_DIR/$LIB_NAME.framework"
FAT_DYLIB_PATH="$FAT_FW_PATH/$LIB_NAME"

# Create the FAT Framework by coping files and creating the fat DYLIB using lipo.
cp -r "$SRC_DIR/" "$FAT_FW_PATH"
lipo "$DYLIBS" -output "$FAT_DYLIB_PATH" -create
install_name_tool -id "@rpath/$LIB_NAME.framework/$LIB_NAME" "$FAT_DYLIB_PATH"

# Extract debug symbols
rm -rf "$LIB_NAME.framework.dSYM" || true
dsymutil "$FAT_DYLIB_PATH" --out "$LIB_NAME.framework.dSYM"

# Convert Framework to XCFramework
rm -rf "$BUILD_DIR/iphoneos" || true
rm -rf "$BUILD_DIR/iphonesimulator" || true
mkdir -p "$BUILD_DIR/iphoneos"
mkdir -p "$BUILD_DIR/iphonesimulator"

IPHONE_OS_FW_PATH="$BUILD_DIR/iphoneos/$LIB_NAME.framework"
IPHONE_SIM_FW_PATH="$BUILD_DIR/iphonesimulator/$LIB_NAME.framework"

cp -R "$FAT_FW_PATH" "$IPHONE_OS_FW_PATH"
cp -R "$FAT_FW_PATH" "$IPHONE_SIM_FW_PATH"

IPHONE_OS_LIB_PATH="$IPHONE_OS_FW_PATH/$LIB_NAME"
IPHONE_SIM_LIB_PATH="$IPHONE_SIM_FW_PATH/$LIB_NAME"

echo "Spliting fat libs..."
xcrun lipo -remove x86_64 "$IPHONE_OS_LIB_PATH" -o "$IPHONE_OS_LIB_PATH"
xcrun lipo -remove arm64 "$IPHONE_SIM_LIB_PATH" -o "$IPHONE_SIM_LIB_PATH"

echo "Creating XCFramework..."
rm -rf "$XCFW_PATH" || true

xcodebuild -create-xcframework -framework "$IPHONE_OS_FW_PATH"/ -framework "$IPHONE_SIM_FW_PATH"/ -output "$XCFW_PATH"
