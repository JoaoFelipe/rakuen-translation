"""This file converts a csv directory into a lang.rb
This is the opposite of lang_to_csv.py
"""

import argparse
import csv
import re
from pathlib import Path
from collections import defaultdict


def to_str(value, indent):
    """Repr with double quotes
    Obtained from https://mail.python.org/pipermail/python-list/2003-April/236940.html
    """
    value = value.replace('@', '@@')
    value = value.replace('"', '+ at +')
    value = value.replace("'", '- at -')
    value = repr(value)[1:-1]
    value = value.replace('- at -', "'")
    value = value.replace('+ at +', r'\"')
    value = value.replace('@@', '@')
    return '"%s"' % value

def symbol(value, indent):
    """Symbol value"""
    return str(value)

def to_int(value, indent):
    """Int value"""
    return str(value)

def journal(value, indent):
    """journal_lang item. Considers the first and last elements"""
    if value in ("nil", "500"):
        return value
    return to_str(value, indent)

def multiline(value, indent):
    """Multiline string"""
    tindent = " " * (indent + 2)
    
    split = re.split(r'(?<!\\)\\n', to_str(value, indent))
    if split[-1] == '"':
        split.pop()
        split[-1] += '\\n"'
    return "\n" + tindent + ('\\n"\\\n' + tindent + '"').join(
        split
    )

def singleline(value, indent):
    """Singleline string"""
    return " " + to_str(value, indent)

def list_str(value, indent):
    """List of strings"""
    return "[{}]".format(
        ", ".join(to_str(x, indent) for x in value),
    )

def eventfn(value, indent):
    """Event item"""
    if isinstance(value, list):
        return " [{}, {}]".format(
            list_str(value[0], indent),
            value[1]
        )
    tindent = " " * (indent + 2)
    return (
        "\n" 
        + tindent 
        + "#------------------------------------------"
        + multiline(value, indent)
    )
    

def to_vars(fil, inputp, name, prefix="", desc=""):
    """Write vars to fil"""
    with open(inputp / (name + ".csv"), "r", encoding="utf-8") as csvf:
        reader = csv.reader(csvf)
        next(reader, None)
        if desc:
            fil.write("# {}\n".format(desc))
        for row in reader:
            extra = " # {}".format(row[2].replace("\n", " ")) if row[2] else ""
            fil.write('{}{} = {}{}\n'.format(
                prefix, row[0], to_str(row[1], 0), extra)
            )
        fil.write("\n")

def to_dict(fil, inputp, name, desc="", keyfn=to_str, valuefn=singleline, default=""):
    """Write dict to fil"""
    with open(inputp / (name + ".csv"), "r", encoding="utf-8") as csvf:
        reader = csv.reader(csvf)
        next(reader, None)
        if desc:
            fil.write("# {}\n".format(desc))
        fil.write("${} = {{\n".format(name))
        written = False
        for row in reader:
            written = True
            extra = " # {}".format(row[2].replace("\n", " ")) if row[2] else ""
            fil.write('  {} =>{},{}\n'.format(
                keyfn(row[0], 2), valuefn(row[1], 2), extra)
            )
        if not written:
            fil.write(default)
        fil.write("}\n\n")

        
def to_list(fil, inputp, name, desc="", valuefn=to_str, default=""):
    """Write list to fil"""
    with open(inputp / (name + ".csv"), "r", encoding="utf-8") as csvf:
        reader = csv.reader(csvf)
        next(reader, None)
        if desc:
            fil.write("# {}\n".format(desc))
        fil.write("${} = [\n".format(name))
        written = False
        for row in reader:
            written = True
            extra = " # {}".format(row[2].replace("\n", " ")) if row[2] else ""
            fil.write('  {},{}\n'.format(
                valuefn(row[1], 2), extra)
            )
        if not written:
            fil.write(default)
        fil.write("]\n\n")

        
def to_events(fil, inputp):
    """Write events_lang to fil"""
    desc = "Events"
    name = "events_lang"
    with open(inputp / (name + ".csv"), "r", encoding="utf-8") as csvf:
        reader = csv.reader(csvf)
        next(reader, None)
        events_lang = defaultdict(lambda: defaultdict(lambda: defaultdict(
            lambda: defaultdict(lambda: ["", ""])
        )))
        clist = None

        for row in reader:
            if row[4] != "-1":
                index = int(row[4])
                if clist is None:
                    clist = [""] * index
                    try:
                        events_lang[row[0]][row[1]][row[2]][row[3]] = [[clist, int(row[5])], row[6]]
                    except:
                        print(row)
                        raise
                else:
                    clist[index] = row[5]
                    if index == len(clist) - 1:
                        clist = None
            else:
                clist = None
                events_lang[row[0]][row[1]][row[2]][row[3]] = [row[5], row[6]]
        
        if desc:
            fil.write("# {}\n".format(desc))
        fil.write("${} = {{\n".format(name))
        for mapid, events in events_lang.items():
            fil.write('  {} => {{\n'.format(
                to_int(mapid, 2),
            ))
            for eventid, pages in events.items():
                fil.write('    {} => {{\n'.format(
                    to_int(eventid, 4),
                ))
                for pageid, positions in pages.items():
                    fil.write('      {} => {{\n'.format(
                        to_int(pageid, 6),
                    ))
                    for position, msg in positions.items():
                        extra = " # {}".format(msg[1].replace("\n", " ")) if msg[1] else ""
                        fil.write('        {} =>{},{}\n'.format(
                            to_int(position, 8), eventfn(msg[0], 8), extra
                        ))
                    fil.write('      },\n')
                fil.write('    },\n')
            fil.write('  },\n')
        fil.write("}\n\n")
        
def to_listdict(fil, inputp, name, desc="", keyfn=to_str, default=""):
    """Write dict of list to fil"""
    with open(inputp / (name + ".csv"), "r", encoding="utf-8") as csvf:
        reader = csv.reader(csvf)
        next(reader, None)
        result = defaultdict(list)
        for row in reader:
            lis = result[row[0]]
            index = int(row[1])
            if index >= len(lis):
                lis.append([row[2], row[3]])
        if desc:
            fil.write("# {}\n".format(desc))
        fil.write("${} = {{\n".format(name))
        written = False
        for key, value in result.items():
            written = True
            comment = [x[1].replace("\n", " ") for x in value]
            extra = " # {}".format(";".join(comment)) if any(comment) else ""
            fil.write('  {} => {},{}\n'.format(
                keyfn(key, 2), list_str([x[0] for x in value], 2), extra)
            )
        if not written:
            fil.write(default)
        fil.write("}\n\n")

def main():
    """Main function"""
    parser = argparse.ArgumentParser(description='Convert csv directory into lang.rb')
    parser.add_argument('input', type=str,
                        help='input csv directory')
    parser.add_argument('output', type=str,
                        help='output lang.rb file')
    args = parser.parse_args()


    inputp = Path(args.input)
    output = Path(args.output)
    
    with open(output, "w", encoding="utf-8") as fil:
        with open(inputp / "header.txt", "r", encoding="utf-8") as inp:
            fil.write(inp.read().replace("\n\n", "\n"))
            fil.write("\n")
            
        to_vars(fil, inputp, "variables", "", "")
        to_dict(fil, inputp, "override_fonts_lang", "Override font names",
                default='  # "5yearsoldfont" => "MS PGothic",\n')
        to_dict(fil, inputp, "override_images_lang",
                "Override Images. Note that the path here is relative to the language folder",
                default='  # "Graphics/Titles/Rakuen1" => "../Ending Credits 8.png",\n')
        to_list(fil, inputp, "title_lang", "Title")
        to_dict(fil, inputp, "menu_lang", "Menu", keyfn=symbol)
        to_vars(fil, inputp, "global_vars", "$")
        to_list(fil, inputp, "end_lang")
        to_dict(fil, inputp, "MOM", "Mom", keyfn=to_int, valuefn=multiline)
        to_dict(fil, inputp, "MOMHINT", keyfn=to_int, valuefn=multiline)
        to_list(fil, inputp, "journal_lang", "Journal", valuefn=journal)
        to_events(fil, inputp)
        to_dict(fil, inputp, "actors_lang", "Actors", keyfn=to_int)
        to_dict(fil, inputp, "animations_lang", "Animations", keyfn=to_int)
        to_listdict(fil, inputp, "armors_lang", "Armors", keyfn=to_int)
        to_dict(fil, inputp, "classes_lang", "Classes", keyfn=to_int)
        to_dict(fil, inputp, "enemies_lang", "Enemies", keyfn=to_int)
        to_listdict(fil, inputp, "items_lang", "Items", keyfn=to_int)
        to_dict(fil, inputp, "mapinfos_lang", "MapInfos", keyfn=to_int)
        to_listdict(fil, inputp, "skills_lang", "Skills", keyfn=to_int)
        to_dict(fil, inputp, "states_lang", "States", keyfn=to_int)
        to_dict(fil, inputp, "system_words", "System", keyfn=symbol)
        to_list(fil, inputp, "system_elements")
        to_dict(fil, inputp, "tilesets_lang", "Tilesets", keyfn=to_int)
        to_dict(fil, inputp, "troops_lang", "Troops", keyfn=to_int)
        to_listdict(fil, inputp, "weapons_lang", "Weapons", keyfn=to_int)


if __name__ == "__main__":
    main()
