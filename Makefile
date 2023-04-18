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

all: masks_png textures_masked ## Generates all files, end-to-end

masks_png: ## Generates masks from SVG files
	mkdir -p masks_png
	convert masks_svg/1a.svg -negate -alpha Off masks_png/1a.png
	convert masks_svg/1b.svg -negate -alpha Off masks_png/1b.png
	convert masks_svg/1c.svg -negate -alpha Off masks_png/1c.png
	convert masks_svg/1d.svg -negate -alpha Off masks_png/1d.png

textures_masked: ## Generates gores and callots using masks
	mkdir -p textures_masked
	magick textures_raw/12237016.png masks_png/1a.png -alpha Off -compose CopyOpacity -composite -trim +repage textures_masked/1a.png
	magick textures_raw/12237016.png masks_png/1b.png -alpha Off -compose CopyOpacity -composite -trim +repage textures_masked/1b.png
	magick textures_raw/12237016.png masks_png/1c.png -alpha Off -compose CopyOpacity -composite -trim +repage textures_masked/1c.png
	magick textures_raw/12237016.png masks_png/1d.png -alpha Off -compose CopyOpacity -composite -trim +repage textures_masked/1d.png
