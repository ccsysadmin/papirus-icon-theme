#!/usr/bin/env bash
# This script creates colored folder icons
#
# Colors of the folder icon:
#
#   @ - primary color
#	. - secondary color
#	" - color of symbol
#	* - color of paper
#
#    ..................
#    ..................
#    ........................................
#    ..************************************..
#    ..************************************..
#    ..************************************..
#    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#    @@@@@@@@@@@@@@@@@@""""@@@@@@@@@@@@@@@@@@
#    @@@@@@@@@@@@@@@@@@""""@@@@@@@@@@@@@@@@@@
#    @@@@@@@@@@@@@@@@@@""""@@@@@@@@@@@@@@@@@@
#    @@@@@@@@@@@@@@@@@@""""@@@@@@@@@@@@@@@@@@
#    @@@@@@@@@@@@@@""""""""""""@@@@@@@@@@@@@@
#    @@@@@@@@@@@@@@@""""""""""@@@@@@@@@@@@@@@
#    @@@@@@@@@@@@@@@@@""""""@@@@@@@@@@@@@@@@@
#    @@@@@@@@@@@@@@@@@@@""@@@@@@@@@@@@@@@@@@@
#    @@@@@@@@@@@@@@""""""""""""@@@@@@@@@@@@@@
#    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

set -eo pipefail

SCRIPT_DIR=$(dirname "$0")
TARGET_DIR="$SCRIPT_DIR/../Papirus"

DEFAULT_COLOR="blue"
SIZES_REGEX="(16x16|22x22|24x24|32x32|48x48|64x64)"
FILES_REGEX="(folder|user)-"

declare -A COLORS

COLORS=(
	# [0] - primary color
	# [1] - secondary color
	# [2] - color of symbol
	# [3] - color of paper
	#
	# | name  | [0]   | [1]   | [2]   | [3]   |
	# |-------|-------|-------|-------|-------|
	[blue]="   #5294e2 #4877b1 #1d344f #dcdcdc"
	[black]="  #4f4f4f #505050 #1c1c1c #dcdcdc"
	[brown]="  #ae8e6c #957552 #3d3226 #dcdcdc"
	[cyan]="   #3cbdb8 #289ea1 #154240 #dcdcdc"
	[grey]="   #9a9a9a #7d7d7d #363636 #dcdcdc"
	[green]="  #83d85e #69ad4c #2e4b21 #dcdcdc"
	[magenta]="#ca71df #b259b8 #47274e #dcdcdc"
	[orange]=" #f49940 #dc8948 #553516 #dcdcdc"
	[red]="    #e25252 #bf4b4b #4f1d1d #dcdcdc"
	[yellow]=" #f5ce46 #e5b732 #564818 #dcdcdc"
	[custom]=" #value_light #value_dark #2a2a2a #dcdcdc"
)

recolor() {
	# args: <old colors> <new colors> <path to file>
	declare -a old_colors=( $1 )
	declare -a new_colors=( $2 )
	local filepath="$3"

	[ -f "$filepath" ] || exit 1

	for (( i = 0; i < "${#old_colors[@]}"; i++ )); do
		sed -i "s/${old_colors[$i]}/${new_colors[$i]}/gI" "$filepath"
	done
}

find "$TARGET_DIR" -regextype posix-extended \
	-regex ".*/${SIZES_REGEX}/places/${FILES_REGEX}${DEFAULT_COLOR}.*" \
	-print0 | while read -d $'\0' file; do

	for color in "${!COLORS[@]}"; do
		[[ "$color" != "$DEFAULT_COLOR" ]] || continue

		new_file="${file/-$DEFAULT_COLOR/-$color}"

		cp -Pv --remove-destination "$file" "$new_file"
		recolor "${COLORS[$DEFAULT_COLOR]}" "${COLORS[$color]}" "$new_file"
	done
done


# Copy color folder icons to derivative themes
COLOR_NAMES="${!COLORS[*]}"  # get a string of colors
COLOR_REGEX="(${COLOR_NAMES// /|})"  # convert the list of colors to regex
DERIVATIVES=(
	ePapirus
	Papirus-Dark
)  # array of derivative icon themes with 16x16 places

find "$TARGET_DIR" -regextype posix-extended \
	-regex ".*/16x16/places/folder-${COLOR_REGEX}.*" \
	-print0 | while read -d $'\0' file; do

	for d in "${DERIVATIVES[@]}"; do
		cp -Pv --remove-destination "$file" "${file/Papirus/$d}"
	done
done


# Create symlinks for Folder Color 0.0.80 and newer
FOLDER_COLOR_MAP=(
	# Icons mapping:
	# Folder Color icon          Papirus icon
	"folder-COLOR-desktop.svg    user-COLOR-desktop.svg"
	"folder-COLOR-downloads.svg  folder-COLOR-download.svg"
	"folder-COLOR-public.svg     folder-COLOR-image-people.svg"
	"folder-COLOR-videos.svg     folder-COLOR-video.svg"
)

for mask in "${FOLDER_COLOR_MAP[@]}"; do
	for color in "${!COLORS[@]}"; do
		icon_mask=( $mask )
		folder_color_icon="${icon_mask[0]/COLOR/$color}"
		icon="${icon_mask[1]/COLOR/$color}"

		find "$TARGET_DIR" -regextype posix-extended \
			-regex ".*/${SIZES_REGEX}/places/${icon}" \
			-print0 | while read -d $'\0' file; do

			base_name="$(basename "$file")"
			dir_name="$(dirname "$file")"

			ln -sfv "$base_name" "$dir_name/$folder_color_icon"
		done
	done
done
