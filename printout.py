import math
import os
import sys
from pathlib import Path

import cairocffi
from rectpack import newPacker


# Standard units for printing
cm_per_inch = 2.54
pt_per_cm = 72 / 2.54

# Below are rough measurements of the widths of the gores. The total sum of the
# gore widths is the circumference of the globe.
# 5195px = 2 gores
# 7814px = 3 gores
# 7821px = 3 gores
# 7839px = 3 gores
# 1304px + 1340px = 1 gore
# 31313px = circumference
globe_diameter_actual_cm = 50
globe_circumference_actual_px = 31313
project_root_dir = Path(__file__).parent

if len(sys.argv) != 8:
    print('printout.py [input] [width] [height] [diameter] [margin] [sep] [output]')
    print('  [input]:     Input images (Must be PNGs)')
    print('  [width]:     Width of PDF in cm (A4 = 21.0)')
    print('  [height]:    Height of PDF in cm (A4 = 29.7)')
    print('  [diameter]:  Diameter of printed globe in cm')
    print('  [margin]:    CSV of Margins for the whole document in cm (top,right,bottom,left)')
    print('  [sep]:       CSV of Margins between images in cm (top,right,bottom,left)')
    print('  [output]:    Output directory of all the printout PDFs')
    print('')
    print('Example: printout.py textures_masked/ 21.0 29.7 20.0 0.2,0.5,0.2,0.5 0,0.5,0,0 printout/')
    exit(1)

textures_masked_dir = project_root_dir.joinpath(sys.argv[1])
document_width_cm = float(sys.argv[2])
document_height_cm = float(sys.argv[3])
globe_diameter_printed_cm = float(sys.argv[4])
margins_cm = list(map(lambda v: float(v), sys.argv[5].split(',')))
sep_cm = list(map(lambda v: float(v), sys.argv[6].split(',')))
printout_dir = project_root_dir.joinpath(sys.argv[7])
printout_dir.mkdir(exist_ok=True)

# Convert document units
document_width_pt = document_width_cm * pt_per_cm
document_height_pt = document_height_cm * pt_per_cm

# Convert globe units
globe_circumference_actual_cm = globe_diameter_actual_cm * math.pi
globe_px_per_cm = globe_circumference_actual_px / globe_circumference_actual_cm
print_scale = globe_diameter_printed_cm / globe_diameter_actual_cm

print('  Original pixels-per-cm:', globe_px_per_cm)
print('       New pixels-per-cm:', globe_px_per_cm / print_scale)
print('Original pixels-per-inch:', globe_px_per_cm * cm_per_inch)
print('     New pixels-per-inch:', globe_px_per_cm * cm_per_inch / print_scale)
print('')

# Read the image dimensions of all the images
print('Reading image dimensions:')
textures_masked_paths = os.listdir(textures_masked_dir)
# Ignore non-PNG files
textures_masked_paths = list(filter(lambda path: '.png' in path, textures_masked_paths))
textures_masked_paths.sort()
rectangles = []
for textures_masked_name in textures_masked_paths:
    print(' - Reading %s...' % str(textures_masked_name), end='', flush=True)
    textures_masked_path = textures_masked_dir\
        .joinpath(str(textures_masked_name))
    image_surface = cairocffi.ImageSurface.create_from_png(
        textures_masked_path.as_posix()
    )
    png_width_px = image_surface.get_width()
    png_height_px = image_surface.get_height()
    png_width_cm = png_width_px / (globe_px_per_cm / print_scale)
    png_height_cm = png_height_px / (globe_px_per_cm / print_scale)
    rectangles.append({
        'name': textures_masked_path.name,
        'width_cm': png_width_cm + sep_cm[1] + sep_cm[3],
        'height_cm': png_height_cm + sep_cm[0] + sep_cm[2],
    })
    print(' Done')

# Pack the "bins" with the images (our printouts)
print('Preparing layout of images...', end='', flush=True)
packer = newPacker()
packer.add_bin(
    document_width_cm - margins_cm[1] - margins_cm[3],
    document_height_cm - margins_cm[0] - margins_cm[2],
    float('inf')
)
for rectangle in rectangles:
    packer.add_rect(
        rectangle['width_cm'],
        rectangle['height_cm'],
        rectangle['name']
    )

packer.pack()
print(' Done')

# Verify all images have been packed.
verify_actual = 0
verify_expected = len(textures_masked_paths)
for abin in packer:
    verify_actual += len(abin)
if verify_actual != verify_expected:
    print('Error: Only %d out of %d were packed.' %
          (verify_actual, verify_expected)
    )
    exit(1)

# Render the PDFs
print('Rendering %d PDFs:' % len(packer))
bin_i = 0
for abin in packer:
    bin_i += 1
    print(' - Rendering %s.pdf...' % bin_i, end='', flush=True)
    printout_path = printout_dir.joinpath('%s.pdf' % bin_i)
    surface = cairocffi.PDFSurface(
        printout_path.as_posix(),
        document_width_pt,
        document_height_pt
    )
    context = cairocffi.Context(surface)
    context.translate(margins_cm[3] * pt_per_cm, margins_cm[0] * pt_per_cm)

    for rect in abin:
        # Render the rectangle (for debugging)
        # context.rectangle(
        #     (rect.x + sep_cm[3]) * pt_per_cm,
        #     (rect.y + sep_cm[0]) * pt_per_cm,
        #     (rect.width - sep_cm[1] - sep_cm[3]) * pt_per_cm,
        #     (rect.height - sep_cm[0] - sep_cm[2]) * pt_per_cm
        # )
        # context.stroke()

        # Open the image
        textures_masked_path = textures_masked_dir\
            .joinpath(rect.rid)
        image_surface = cairocffi.ImageSurface.create_from_png(
            textures_masked_path.as_posix()
        )

        # Render the image
        context.save()
        context.translate(
            (rect.x + sep_cm[3]) * pt_per_cm,
            (rect.y + sep_cm[0]) * pt_per_cm,
        )
        new_scale = 1 / (globe_px_per_cm / print_scale) * pt_per_cm
        context.scale(
            new_scale
        )
        context.set_source_surface(image_surface, 0, 0)
        context.paint()
        context.restore()

    surface.finish()
    print(' Done')
