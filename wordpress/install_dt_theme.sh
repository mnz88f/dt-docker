#!/bin/bash

TMP_FOLDER="/tmp/$(uuidgen)"
DT_ZIP=disciple-tools-theme.zip
DT_URL=https://github.com/DiscipleTools/disciple-tools-theme/releases/latest/download/disciple-tools-theme.zip

local deps=("wget" "unzip" "uuidgen")
for dep in "${deps[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
        echo "$dep not found. Please install using your package manager."
        exit 1
    fi
done

if [ ! -e "$DT_ZIP" ]; then
    wget $DT_URL $DT_ZIP
fi

if [ ! -f "$DT_ZIP" ]; then
    echo "$DT_ZIP not found!"
    exit 1
fi

echo "Extracting to $TMP_FOLDER"
unzip $DT_ZIP -d $TMP_FOLDER
docker cp "$TMP_FOLDER"/* wordpress:/var/www/html/wp-content/themes/
rm -rf $TMP_FOLDER
docker exec wordpress chown -R www-data:www-data /var/www/html/wp-content/themes
