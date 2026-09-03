from PIL import Image
import os

img_path = 'assets/images/leaves_grid.png'
img = Image.open(img_path)
width, height = img.size

# The image is a 2x2 grid. We need to find the bounding box of each leaf or just cut it into 4 and trim.
# To ensure perfect alignment in Flutter, it's best to trim the transparent whitespace around each leaf.
# Then Flutter can position it perfectly at the bottom right.

def process_quadrant(box, name):
    quadrant = img.crop(box)
    # Get bounding box of non-transparent pixels
    bbox = quadrant.getbbox()
    if bbox:
        trimmed = quadrant.crop(bbox)
        trimmed.save(f'assets/images/{name}.png')
        print(f'Saved {name}.png with size {trimmed.size}')
    else:
        quadrant.save(f'assets/images/{name}.png')
        print(f'Saved {name}.png (empty?)')

half_w = width // 2
half_h = height // 2

process_quadrant((0, 0, half_w, half_h), 'leaf_schemes')       # Purple
process_quadrant((half_w, 0, width, half_h), 'leaf_hospitals') # Green
process_quadrant((0, half_h, half_w, height), 'leaf_documents')# Blue
process_quadrant((half_w, half_h, width, height), 'leaf_reminders') # Pink
