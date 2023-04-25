.PHONY: help
.DEFAULT_GOAL := help

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

help:
	@python3 -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

textures_raw.tar.gz:
	tar --verbose --create --gzip --file textures_raw.tar.gz textures_raw/*.jp2

textures_raw: ## Extracts the textures from the zip file and fixes a corrupt file
	tar --extract --file textures_raw.tar.gz --directory ./
	gdal_translate -of PNG -b 1 -b 2 -b 3 textures_raw/12237016.jp2 textures_raw/12237016.png --config GDAL_SKIP JP2MrSID --config GDAL_PAM_ENABLED NO

masks_png: ## Generates masks from SVG files
	mkdir -p masks_png
	magick masks_svg/1a.svg -negate -alpha Off masks_png/1a.png
	magick masks_svg/1b.svg -negate -alpha Off masks_png/1b.png
	magick masks_svg/1c.svg -negate -alpha Off masks_png/1c.png
	magick masks_svg/1d.svg -negate -alpha Off masks_png/1d.png
	magick masks_svg/2a.svg -negate -alpha Off masks_png/2a.png
	magick masks_svg/2b.svg -negate -alpha Off masks_png/2b.png
	magick masks_svg/2c.svg -negate -alpha Off masks_png/2c.png
	magick masks_svg/3a.svg -negate -alpha Off masks_png/3a.png
	magick masks_svg/3b.svg -negate -alpha Off masks_png/3b.png
	magick masks_svg/3c.svg -negate -alpha Off masks_png/3c.png
	magick masks_svg/4a.svg -negate -alpha Off masks_png/4a.png
	magick masks_svg/4b.svg -negate -alpha Off masks_png/4b.png
	magick masks_svg/4c.svg -negate -alpha Off masks_png/4c.png
	magick masks_svg/4d.svg -negate -alpha Off masks_png/4d.png
	magick masks_svg/4e.svg -negate -alpha Off masks_png/4e.png

textures_masked: ## Generates gores and callots using masks
	mkdir -p textures_masked
	magick textures_raw/12237016.png masks_png/1a.png -alpha Off -compose CopyOpacity -composite -trim +repage textures_masked/1a.png
	magick textures_raw/12237016.png masks_png/1b.png -alpha Off -compose CopyOpacity -composite -trim +repage textures_masked/1b.png
	magick textures_raw/12237016.png masks_png/1c.png -alpha Off -compose CopyOpacity -composite -trim +repage textures_masked/1c.png
	magick textures_raw/12237016.png masks_png/1d.png -alpha Off -compose CopyOpacity -composite -trim +repage textures_masked/1d.png
	magick textures_raw/12237017.jp2 masks_png/2a.png -alpha Off -compose CopyOpacity -composite -trim +repage textures_masked/2a.png
	magick textures_raw/12237017.jp2 masks_png/2b.png -alpha Off -compose CopyOpacity -composite -trim +repage textures_masked/2b.png
	magick textures_raw/12237017.jp2 masks_png/2c.png -alpha Off -compose CopyOpacity -composite -trim +repage textures_masked/2c.png
	magick textures_raw/12237018.jp2 masks_png/3a.png -alpha Off -compose CopyOpacity -composite -trim +repage textures_masked/3a.png
	magick textures_raw/12237018.jp2 masks_png/3b.png -alpha Off -compose CopyOpacity -composite -trim +repage textures_masked/3b.png
	magick textures_raw/12237018.jp2 masks_png/3c.png -alpha Off -compose CopyOpacity -composite -trim +repage textures_masked/3c.png
	magick textures_raw/12237019.jp2 masks_png/4a.png -alpha Off -compose CopyOpacity -composite -trim +repage textures_masked/4a.png
	magick textures_raw/12237019.jp2 masks_png/4b.png -alpha Off -compose CopyOpacity -composite -trim +repage textures_masked/4b.png
	magick textures_raw/12237019.jp2 masks_png/4c.png -alpha Off -compose CopyOpacity -composite -trim +repage textures_masked/4c.png
	magick textures_raw/12237019.jp2 masks_png/4d.png -alpha Off -compose CopyOpacity -composite -trim +repage textures_masked/4d.png
	magick textures_raw/12237019.jp2 masks_png/4e.png -alpha Off -compose CopyOpacity -composite -trim +repage textures_masked/4e.png

printout_a4_20cm: ## Generates printouts that generates a globe with a diameter of 20 cm
	poetry run python printout.py 21.0 29.7 20 0.5 0.5
