#!/bin/bash

# App Icon Generator Script for iOS
# This script generates all required app icon sizes from a 1024x1024 source image

SOURCE_IMAGE="/Users/sabrielmakhoukhi/Desktop/scrolldeeds/scrolldeeds/Assets.xcassets/AppIcon.appiconset/1024.png"
OUTPUT_DIR="/Users/sabrielmakhoukhi/Desktop/scrolldeeds/scrolldeeds/Assets.xcassets/AppIcon.appiconset"

echo "🎨 Generating all app icon sizes..."
echo "📁 Source: $SOURCE_IMAGE"
echo "📁 Output: $OUTPUT_DIR"
echo ""

# Check if source exists
if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "❌ Error: Source image not found at $SOURCE_IMAGE"
    exit 1
fi

# Function to resize image using sips (built-in macOS tool)
resize_icon() {
    local size=$1
    local filename=$2
    
    echo "  → Creating ${filename} (${size}x${size}px)..."
    sips -z $size $size "$SOURCE_IMAGE" --out "$OUTPUT_DIR/$filename" > /dev/null 2>&1
}

# Generate all required iOS app icon sizes
echo "📱 Generating iPhone app icons..."

# iPhone App Icon - 60pt
resize_icon 120 "iphone_60pt@2x.png"
resize_icon 180 "iphone_60pt@3x.png"

# iPhone Settings - 29pt
resize_icon 58 "iphone_settings@2x.png"
resize_icon 87 "iphone_settings@3x.png"

# iPhone Spotlight - 40pt
resize_icon 80 "iphone_spotlight@2x.png"
resize_icon 120 "iphone_spotlight@3x.png"

# iPhone Notification - 20pt
resize_icon 40 "iphone_notification@2x.png"
resize_icon 60 "iphone_notification@3x.png"

# iPad App Icon - 76pt
echo "📱 Generating iPad app icons..."
resize_icon 76 "ipad_76pt@1x.png"
resize_icon 152 "ipad_76pt@2x.png"

# iPad Pro App Icon - 83.5pt
resize_icon 167 "ipad_pro@2x.png"

# iPad Settings - 29pt
resize_icon 29 "ipad_settings@1x.png"
resize_icon 58 "ipad_settings@2x.png"

# iPad Spotlight - 40pt
resize_icon 40 "ipad_spotlight@1x.png"
resize_icon 80 "ipad_spotlight@2x.png"

# iPad Notification - 20pt
resize_icon 20 "ipad_notification@1x.png"
resize_icon 40 "ipad_notification@2x.png"

echo ""
echo "✅ All app icon sizes generated successfully!"
echo ""
echo "📋 Generated files:"
ls -lh "$OUTPUT_DIR"/*.png | awk '{print "   " $9 " (" $5 ")"}'
echo ""
echo "🎉 Done! Your app icons are ready in Xcode!"

