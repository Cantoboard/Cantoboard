#!/bin/sh
LIB_NAME=Rime
DYLIBS="src/librime.1.7.3.dylib"
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
OUT_DSYM_PATH="$FW_PATH.dSYM/Contents/Resources/DWARF"
INFO_PLIST="$FW_PATH.dSYM/Contents/Info.plist"
mkdir -p "$OUT_DSYM_PATH"
cp "$SOURCE_INFO_PLIST" "$INFO_PLIST"
lipo $DYLIBS -output "$OUT_DSYM_PATH/$LIB_NAME" -create