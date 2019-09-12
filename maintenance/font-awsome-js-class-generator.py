#!/usr/bin/env python3

import sys
import os
import glob
import re


# This is a helper script to be run once awesome-fonts are upgraded.
# It creates js wrappers to be used within QML as:
#
# .pragma library
#
# var fa_adjust                  = "\uf042"
# var fa_adn                     = "\uf170"
# var fa_align_center            = "\uf037"
# var fa_align_justify           = "\uf039"
# var fa_align_left              = "\uf036"
# var fa_align_right             = "\uf038"

# extract some worker paths
project_path = os.path.realpath(sys.path[0] + '/..') + '/'
js_path = project_path + 'fa-js-wrapper/'

# create_js_wrapper() is our magic worker
def create_js_wrapper(svg_full_path):
    js_wrapper_base_name = os.path.basename(svg_full_path).replace('.svg', '').replace('-', '_')
    js_wrapper_file = js_path + os.path.basename(svg_full_path).replace('.svg', '.js')
    print('Create wrapper "' + js_wrapper_file + '...')
    f = open(js_wrapper_file, 'w')
    # header
    f.write('.pragma library\n\n')
    # helper
    f.write('// helper for easy coloring\n')
    f.write('function icon(symbol, color) {\n')
    f.write('    var colorStart=""\n')
    f.write('    var colorEnd=""\n')
    f.write('    if(color !== null) {\n')
    f.write('        colorStart="<font color=\'"+color+"\'>"\n')
    f.write('        colorEnd="</font>"\n')
    f.write('    }\n')
    f.write('    return colorStart+symbol+colorEnd\n')
    f.write('}')
    f.write('\n\n')

    # alias variables
    for line in open(svg_full_path):
        if "glyph-name=" in line and "unicode=" in line:
            line = line.replace('<glyph', '')
            line = line.replace(' ', '')
            glyph_name = ''
            unicode = ''
            next_is_glyph_name = False
            next_is_unicode = False
            for entry in line.split('"'):
                if next_is_glyph_name:
                    glyph_name = entry.replace('-', '_')
                    next_is_glyph_name = False
                if next_is_unicode:
                    unicode = entry.replace(';', '').replace('&', '').replace('#', '').replace('x', '')
                    next_is_unicode = False
                if 'glyph-name=' in entry:
                    next_is_glyph_name = True
                if 'unicode=' in entry:
                    next_is_unicode = True
            if unicode != '' and glyph_name != '':
                glyph_name_len = len(glyph_name)
                spacer = ''
                spacelen = 40
                if glyph_name_len < spacelen:
                    spacer = ' ' * int(spacelen - glyph_name_len)
                f.write('var ' + js_wrapper_base_name + '_' + glyph_name + spacer + '= "\\u' + unicode + '"\n')
    f.close()

# check / add FortAwesome
awesome_path = os.path.realpath(project_path + 'Font-Awesome') + '/'
if not os.path.exists(awesome_path):
    os.chdir(project_path)
    print("Add FortAwesome git submodule...")
    if os.system('git submodule add https://github.com/FortAwesome/Font-Awesome.git') != 0 or not os.path.exists(awesome_path):
        raise Exception('Something went wrong creating FortAwesome submodule!')
else:
    print("FortAwesome git submodule found.")

# create js-wrapper path
if not os.path.exists(js_path):
   os.mkdir(js_path)
   print('"' + js_path + '" created.')


# get symbols from FortAwesome's svgs - they are much easier to parse
svg_path = os.path.realpath(awesome_path + 'webfonts') + '/'

# parse svgs and create our wrappers
for svg in glob.glob(svg_path + '*.svg'):
    create_js_wrapper(svg)

