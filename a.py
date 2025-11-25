from PIL import Image
from matplotlib import pyplot as plt
import math

img = Image.open("image.pgm")
img = img.convert(mode='RGB')

dark_border = (13, 37 ,75)
dark_passage = (36, 61 ,101)
light_border = (50, 78 , 128)
light_passage = (74, 102 ,149)

pixels = img.load()
for i in range(img.size[0]):
    for j in range(img.size[1]):
        ratio_x = abs(img.size[0]/2 -i) / (img.size[0]/2)
        ratio_y = abs(img.size[1]/2 -j) / (img.size[1]/2)
        ratio = math.sqrt(ratio_x*ratio_x + ratio_y*ratio_y)
        if pixels[i,j] != (0, 0, 0):
            pixels[i,j] = (
                int(dark_passage[0]*ratio + light_passage[0]*(1-ratio)),
                int(dark_passage[1]*ratio + light_passage[1]*(1-ratio)),
                int(dark_passage[2]*ratio + light_passage[2]*(1-ratio)),
            )
        else:
            pixels[i,j] = (
                int(dark_border[0]*ratio + light_border[0]*(1-ratio)),
                int(dark_border[1]*ratio + light_border[1]*(1-ratio)),
                int(dark_border[2]*ratio + light_border[2]*(1-ratio)),
            )

box = (1, 1, img.width-1 , img.height - 1)
img = img.crop(box)


img.save("color.png")
