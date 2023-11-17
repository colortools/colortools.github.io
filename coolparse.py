from lxml import html
import requests

f = open("data/ral.html", "r")
page = f.read()
tree = html.fromstring(page)

colorNames = tree.xpath('//a[@class="farbe " or @class="farbe dark"]/div[@class="subtext"]/text()')
colorRgb = tree.xpath('//a[@class="farbe " or @class="farbe dark"]/@style')

index = 0
#for name in colorNames:
#    print(name, " is ", colorRgb[index])
#    index = index + 1

# print('Colors: ', colorRgb)

print('Names: ', len(colorNames))
print('Rgb: ', len(colorRgb))
