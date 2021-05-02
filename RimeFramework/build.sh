#!/bin/sh

if [ -z "$LIBRIME_ROOT" ]; then
echo "Please set LIBRIME_ROOT to point to the librime dir."
exit 0
fi

LIB_NAME=Rime
DYLIBS="$LIBRIME_ROOT/dist/lib/librime.1.7.3.dylib"
SOURCE_INFO_PLIST="src/Info.plist"
OUT_DIR="."

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
