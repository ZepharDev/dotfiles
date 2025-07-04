#!/bin/bash
# filepath: /home/zephar/.config/scripts/selectpaper.sh

# Configuration Zephar
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
CONFIG="$HOME/.config/hypr/hyprpaper.conf"
CACHE_DIR="$HOME/.cache/hypr"
LAST_WALL="$CACHE_DIR/last_wallpaper"

# Create directory if it does not exist
mkdir -p "$CACHE_DIR"

# Function to handle errors
error_handler() {
    notify-send "Error" "No se pudo aplicar el wallpaper: $1" -u critical
    exit 1
}

# Check necessary directories and files
[ ! -d "$WALLPAPER_DIR" ] && error_handler "Directorio de wallpapers no encontrado"
[ ! -d "$(dirname "$CONFIG")" ] && error_handler "Directorio de configuración no encontrado"

# Being able to selected a wallpaper
WALL=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) -printf "%f\n" | \
     rofi -dmenu -config ~/.config/rofi/wallpaper.rasi -i -p "Wallpaper" -theme-str 'window {width: 50%;}')

# Verify
[ -z "$WALL" ] && exit 0

# Write the full path of the wallpaper
WALL_PATH="$WALLPAPER_DIR/$WALL"
[ ! -f "$WALL_PATH" ] && error_handler "Archivo no encontrado"

# Obtener monitores activos
MONITORS=$(hyprctl monitors -j | jq -r '.[].name') || error_handler "Error al obtener monitores"

# Create new config
{
    echo "# WO configuration generated by wallpaper-menu.sh"
    echo "preload = $WALL_PATH"
    echo ""
    for monitor in $MONITORS; do
        echo "wallpaper = $monitor,$WALL_PATH"
    done
} > "$CONFIG"

# This saves the last selected wallpapers
echo "$WALL_PATH" > "$LAST_WALL"

# Load the wallpaper
if pgrep -x hyprpaper >/dev/null; then
    pkill -SIGUSR2 hyprpaper || {
        pkill hyprpaper
        sleep 1
        hyprpaper &
    }
else
    hyprpaper &
fi

# Check if hyprpaper is working
sleep 1
if ! pgrep -x hyprpaper >/dev/null; then
    hyprpaper &
    sleep 1
fi

# With this we finish the code, and it will send us a notification
# depending on whether it was applied or no
if pgrep -x hyprpaper >/dev/null; then
    notify-send "wallpaper appplied correctly" "$(basename "$WALL_PATH")" -i "$WALL_PATH"
else
    error_handler "Could not apply wallpaper"
fi

