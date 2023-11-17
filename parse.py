# The interesting bits to parse:
#
# <a href="https://www.ral-farben.de/farbe/ral-design-system-plus/ral-000-15-00/7043" class="farbe " style="background-color:#252626" data-brightness="35.452">
# 	<span>RAL</span>
# 	<span class="number">000 15 00</span>
# 	<div class="subtext">Tintenschwarz<br/>Ink black</div>
# </a>
#
# https://docs.python.org/3/library/html.parser.html

# <a href="https://www.ral-farben.de/farbe/ral-design-system-plus/ral-080-40-30/7413" class="farbe " style="background-color:#6B5B2F" data-brightness="81.878"><span>RAL</span><span class="number">080 40 30</span><div class="subtext">Ockergrün<br/>Ochre green</div></a>
# <a href="https://www.ral-farben.de/farbe/ral-design-system-plus/ral-080-40-30/7413" class="farbe " style="background-color:#6B5B2F" data-brightness="81.878"><span>RAL</span><span class="number">080 40 30</span><div class="subtext">Ockergrün<br/>Ochre green</div></a>

import re
import csv
import math 
import os

from html.parser import HTMLParser

currentColor = {}
colors = []
colorCodeRegex = re.compile(r'\s*#(.*)')
currentRange = ''

ranges = {
    'Weiß- und Off-White-Töne': 'data/ral-weiss.html',
    'Schwarz- und Grautöne': 'data/ral-grau.html', 
    'Rottöne': 'data/ral-rot.html', 
    'Gelbtöne': 'data/ral-gelb.html', 
    'Grüntöne': 'data/ral-gruen.html', 
    'Blautöne': 'data/ral-blau.html'
}

RGB_SCALE = 255
CMYK_SCALE = 100

def convert_hex_to_decimal(hex_str):
    return math.trunc(sum(int(x, 16) * math.pow(16, len(hex_str)-i-1) for i, x in enumerate(hex_str)))

def rgb_to_cmyk(rgb):
    r = convert_hex_to_decimal(rgb[0:2])
    g = convert_hex_to_decimal(rgb[2:4])
    b = convert_hex_to_decimal(rgb[4:6])
    if (r, g, b) == (0, 0, 0):
        # black
        return 0, 0, 0, CMYK_SCALE

    # rgb [0,255] -> cmy [0,1]
    c = 1 - r / RGB_SCALE
    m = 1 - g / RGB_SCALE
    y = 1 - b / RGB_SCALE

    # extract out k [0, 1]
    min_cmy = min(c, m, y)
    c = (c - min_cmy) / (1 - min_cmy)
    m = (m - min_cmy) / (1 - min_cmy)
    y = (y - min_cmy) / (1 - min_cmy)
    k = min_cmy

    # rescale to the range [0,CMYK_SCALE]
    return math.trunc(c * CMYK_SCALE), math.trunc(m * CMYK_SCALE), math.trunc(y * CMYK_SCALE), math.trunc(k * CMYK_SCALE)

def getAttributeValue(attrs, key):
    for attr in attrs:
        if attr[0] == key:
            return attr[1]
    return None

class MyHTMLParser(HTMLParser):
    global currentColor
    foundLinkTag = False
    foundName = False
    divCount = 0
    spanCount = 0
    def handle_starttag(self, tag, attrs):
        if tag == 'a' and self.foundLinkTag == False: 
            value = getAttributeValue(attrs, 'class')
            if value is not None and 'farbe' in value:
                self.foundLinkTag = True
                # get color code from a tag
                style = getAttributeValue(attrs, 'style')
                colorCode = colorCodeRegex.search(style).group(1)
                url = getAttributeValue(attrs, 'href')
                currentColor['rgb'] = colorCode
                (c, m, y, k) = rgb_to_cmyk(colorCode)
                currentColor['cmyk'] = str(c) + ' ' + str(m) + ' ' + str(y) + ' ' + str(k)
                currentColor['url'] = url
                if 'dark' in value:
                    currentColor['dark'] = 1
                else:
                    currentColor['dark'] = 0
        else:
            if self.foundLinkTag == True:
                if tag == 'span':
                    self.spanCount = self.spanCount + 1
                if tag == 'div':
                    self.divCount = self.divCount + 1

    def handle_endtag(self, tag):
        if tag == 'a' and self.foundLinkTag == True:
            self.foundLinkTag = False
            self.spanCount = 0
            self.divCount = 0
            self.foundName = False
            currentColor['range'] = currentRange
            if 'nameDE' in currentColor:
                colors.append(currentColor.copy())
            currentColor.clear()

    def handle_data(self, data):
        if self.foundLinkTag == True and self.spanCount == 2:
            currentColor['ral'] = data
            self.spanCount = self.spanCount + 1
        if self.foundLinkTag == True and self.divCount == 2:            
            currentColor['nameEN'] = data
            self.divCount = self.divCount + 1
        if self.foundLinkTag == True and self.divCount == 1:            
            currentColor['nameDE'] = data
            self.divCount = self.divCount + 1

with open('data/colors.csv', 'w') as csv_file:  
    writer = csv.writer(csv_file)
    writer.writerow(['rgb', 'cmyk', 'url', 'dark', 'ral', 'nameDE', 'nameEN', 'range'])

for key, value in ranges.items():
    colors.clear()
    currentRange = key
    f = open(value, "r")
    parser = MyHTMLParser()
    parser.feed(f.read())    

    with open('data/colors.csv', 'a') as csv_file:  
        writer = csv.writer(csv_file)
        for c in colors:
            writer.writerow(c.values())