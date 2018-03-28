"""This file converts a csv directory into a lang.rb
This is the opposite of lang_to_csv.py
"""

import argparse
import csv
import re
import os
from contextlib import contextmanager
from pathlib import Path
from collections import defaultdict


VARIABLES = {}


@contextmanager
def read_csv(input_name, header=True):
    """Fix \r\r\n"""
    temp_name = str(input_name) + ".temp"
    with open(input_name, "rb") as inp, open(temp_name, "wb") as out:
        out.write(inp.read().replace(b"\r\r\n", b"\r\n"))
    with open(temp_name, "rU", encoding="utf-8") as csvf:
        reader = csv.reader(csvf)
        if header:
            next(reader, None)
        yield reader
    os.remove(temp_name)


def replace_var(var, text):
    code = False
    temp = ""
    result = ""
    for i, l in enumerate(text):
        if code:
            if l == "}":
                code = False

                result += var.get(temp, "#{{{}}}".format(temp))
                temp = ""
            else:
                temp += l
        elif l == "#":
            temp = "#"
        elif l == "{" and temp == "#":
            temp = ""
            code = True
        else:
            result += temp + l
            temp = ""
    return result


def to_str(value, indent):
    """Repr with double quotes
    Obtained from https://mail.python.org/pipermail/python-list/2003-April/236940.html
    """
    value = replace_var(VARIABLES, value)
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


def to_vars(fil, inputp, name, final=False, prefix="", desc=""):
    """Write vars to fil"""
    with read_csv(inputp / (name + ".csv")) as reader:
        if desc and not final:
            fil.write("# {}\n".format(desc))
        for row in reader:
            extra = ""
            if row[2] and not final:
                extra = " # {}".format(row[2].replace("\n", " "))
            fil.write('{}{} = {}{}\n'.format(
                prefix, row[0], to_str(row[1], 0), extra)
            )
        fil.write("\n")

def to_dict(fil, inputp, name, desc="", final=False, keyfn=to_str, valuefn=singleline, default=""):
    """Write dict to fil"""
    with read_csv(inputp / (name + ".csv")) as reader:
        if desc and not final:
            fil.write("# {}\n".format(desc))
        fil.write("${} = {{\n".format(name))
        written = False
        for row in reader:
            written = True
            extra = ""
            if row[2] and not final:
                extra = " # {}".format(row[2].replace("\n", " "))
            fil.write('  {} =>{},{}\n'.format(
                keyfn(row[0], 2), valuefn(row[1], 2), extra)
            )
        if not written:
            fil.write(default)
        fil.write("}\n\n")


def to_list(fil, inputp, name, desc="", final=False, valuefn=to_str, default=""):
    """Write list to fil"""
    with read_csv(inputp / (name + ".csv")) as reader:
        if desc and not final:
            fil.write("# {}\n".format(desc))
        fil.write("${} = [\n".format(name))
        written = False
        for row in reader:
            written = True
            extra = ""
            if row[2] and not final:
                extra = " # {}".format(row[2].replace("\n", " "))
            fil.write('  {},{}\n'.format(
                valuefn(row[1], 2), extra)
            )
        if not written:
            fil.write(default)
        fil.write("]\n\n")


def to_events(fil, inputp, final=False):
    """Write events_lang to fil"""
    desc = "Events"
    name = "events_lang"

    with read_csv(inputp / (name + ".csv")) as reader:
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

        if desc and not final:
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
                        extra = ""
                        if msg[1] and not final:
                            extra = " # {}".format(msg[1].replace("\n", " "))
                        fil.write('        {} =>{},{}\n'.format(
                            to_int(position, 8), eventfn(msg[0], 8), extra
                        ))
                    fil.write('      },\n')
                fil.write('    },\n')
            fil.write('  },\n')
        fil.write("}\n\n")

def to_listdict(fil, inputp, name, desc="", final=False, keyfn=to_str, default=""):
    """Write dict of list to fil"""
    with read_csv(inputp / (name + ".csv")) as reader:
        result = defaultdict(list)
        for row in reader:
            lis = result[row[0]]
            index = int(row[1])
            if index >= len(lis):
                lis.append([row[2], row[3]])
        if desc and not final:
            fil.write("# {}\n".format(desc))
        fil.write("${} = {{\n".format(name))
        written = False
        for key, value in result.items():
            written = True
            comment = [x[1].replace("\n", " ") for x in value]
            extra = ""
            if any(comment) and not final:
                extra = " # {}".format(";".join(comment))
            fil.write('  {} => {},{}\n'.format(
                keyfn(key, 2), list_str([x[0] for x in value], 2), extra)
            )
        if not written:
            fil.write(default)
        fil.write("}\n\n")


def csv_to_lang(inputp, output, outfont="", final=False):
    with open(output, "w", encoding="utf-8") as fil:
        with open(inputp / "header.txt", "r", encoding="utf-8") as inp:
            fil.write(inp.read().replace("\n\n", "\n"))
            fil.write("\n")

        if final:
            with read_csv(inputp / "variables.csv") as reader:
                var = {row[0]: row[1] for row in reader}
                for key, value in var.items():
                    VARIABLES[key] = replace_var(VARIABLES, value)
        else:
            to_vars(fil, inputp, "variables", False, "", "")

        if outfont:
            with open(outfont, "w", encoding="utf-8") as font:
                to_dict(font, inputp, "override_fonts_lang", "Override font names", final,
                        default='  # "5yearsoldfont" => "MS PGothic",\n')
        else:
            to_dict(fil, inputp, "override_fonts_lang", "Override font names",
                        default='  # "5yearsoldfont" => "MS PGothic",\n')

        to_dict(fil, inputp, "override_images_lang",
                "Override Images. Note that the path here is relative to the language folder", final,
                default='  # "Graphics/Titles/Rakuen1" => "../Ending Credits 8.png",\n')
        to_list(fil, inputp, "title_lang", "Title", final)
        to_dict(fil, inputp, "menu_lang", "Menu", final, keyfn=symbol)
        to_vars(fil, inputp, "global_vars", final, "$")
        to_list(fil, inputp, "end_lang", final=final)
        to_dict(fil, inputp, "MOM", "Mom", final, keyfn=to_int, valuefn=multiline)
        to_dict(fil, inputp, "MOMHINT", final=final, keyfn=to_int, valuefn=multiline)
        to_list(fil, inputp, "journal_lang", "Journal", final, valuefn=journal)
        to_events(fil, inputp, final)
        to_dict(fil, inputp, "actors_lang", "Actors", final, keyfn=to_int)
        to_dict(fil, inputp, "animations_lang", "Animations", final, keyfn=to_int)
        to_listdict(fil, inputp, "armors_lang", "Armors", final, keyfn=to_int)
        to_dict(fil, inputp, "classes_lang", "Classes", final, keyfn=to_int)
        to_dict(fil, inputp, "enemies_lang", "Enemies", final, keyfn=to_int)
        to_listdict(fil, inputp, "items_lang", "Items", final, keyfn=to_int)
        to_dict(fil, inputp, "mapinfos_lang", "MapInfos", final, keyfn=to_int)
        to_listdict(fil, inputp, "skills_lang", "Skills", final, keyfn=to_int)
        to_dict(fil, inputp, "states_lang", "States", final, keyfn=to_int)
        to_dict(fil, inputp, "system_words", "System", final, keyfn=symbol)
        to_list(fil, inputp, "system_elements", final=final)
        to_dict(fil, inputp, "tilesets_lang", "Tilesets", final, keyfn=to_int)
        to_dict(fil, inputp, "troops_lang", "Troops", final, keyfn=to_int)
        to_listdict(fil, inputp, "weapons_lang", "Weapons", final, keyfn=to_int)

def main():
    """Main function"""
    parser = argparse.ArgumentParser(description='Convert csv directory into lang.rb')
    parser.add_argument('input', type=str,
                        help='input csv directory')
    parser.add_argument('output', type=str,
                        help='output lang.rb file')
    parser.add_argument('--final', action='store_true',
                        help='create lang.rb file without temporary vars')
    parser.add_argument('-f', "--font", type=str, default="",
                        help='output font.rb file')

    args = parser.parse_args()


    csv_to_lang(
        Path(args.input),
        Path(args.output),
        args.font,
        args.final
    )


if __name__ == "__main__":
    main()
