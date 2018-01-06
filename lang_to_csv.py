"""This file converts a lang.rb into a csv directory with files
The reason for using Python for it instead of Ruby is that we want to keep 
ruby interpolated strings intact. Thus, by using a different, yet similar 
syntax, we avoid the trouble of implementing a custom parser"""

import argparse
from pathlib import Path
import csv
import re

RE_FLAGS = re.MULTILINE | re.UNICODE


def access(container, index, default=""):
    """Ttry to access index of container. Return default if it fails"""
    try:
        return container[index]
    except (KeyError, IndexError):
        return default


def rows_to_file(output, name, rows):
    """Write rows into csv"""
    with open(output / (name + ".csv"), 'w') as csvfile:
        writer = csv.writer(csvfile, quoting=csv.QUOTE_NONNUMERIC,
                            lineterminator='\n')
        writer.writerows(rows)


def load_file(name):
    """Convert lang.rb syntax to python and execute it"""
    with open(name, "rb") as fil:
        text = fil.read().decode("utf-8").replace("\n$", "\ng__")

        text = re.sub(r'(:\w+)\s*=>', r'"\1" :', text, RE_FLAGS)
        text = re.sub(r'(_|\W)nil(_|\W)', r'\1None\2', text, RE_FLAGS)

        text = text.replace("=>", ":")
    
        variables = {}
        exec(text, variables, variables)
        del variables['__builtins__']
        header = text[:next(re.finditer('^\w', text, RE_FLAGS)).span()[0]] 
    return variables, header


def vars_to_csv(output, name, translation, original, prefix="", keys=[]):
    """Write variables to file"""
    rows = [["name", "value", "comments", "original"]]
    for var in keys:
        pyvar = prefix + var
        rows.append([
            var, translation.get(pyvar, ""), "", original.get(pyvar, "")
        ])
        del translation[pyvar]

    rows_to_file(output, name, rows)


def events_lang(output, translation, original):
    """Write events to file events_lang.csv"""
    name = "events_lang"
    pyvar = "g__" + name
    if pyvar not in translation:
        return
    original_var = original.get(pyvar, {})
    rows = [["map", "event", "page", "position", "index", "text", "comment", "original"]]
    for mapid, events in translation[pyvar].items():
        oevents = access(original_var, mapid)
        for eventid, pages in events.items():
            opages = access(oevents, eventid)
            for pageid, texts in pages.items():
                otexts = access(opages, pageid)
                for textid, msg in texts.items():
                    omsg = access(otexts, textid)
                    if isinstance(msg, list):
                        rows.append([
                            mapid, eventid, pageid, textid, 
                            len(msg[0]), msg[-1], "", access(omsg, -1)
                        ])
                        omsg0 = access(omsg, 0, [])
                        for i, item in enumerate(msg[0]):
                            rows.append([
                                mapid, eventid, pageid, textid, 
                                i, item, "", access(omsg0, i)
                            ])
                    else:
                        rows.append([
                            mapid, eventid, pageid, textid, 
                            -1, msg, "", omsg
                        ])
    rows_to_file(output, name, rows)
    del translation[pyvar]


def dict_to_csv(output, name, translation, original):
    """Write dict variable to file"""
    pyvar = "g__" + name
    if pyvar not in translation:
        return
    original_var = original.get(pyvar, {})
    rows = [["key", "value", "comments", "original"]]
    for key, value in translation[pyvar].items():
        rows.append([key, value, "", access(original_var, key)])

    rows_to_file(output, name, rows)
    del translation[pyvar]


def list_to_csv(output, name, translation, original):
    """Write list variable to file"""
    pyvar = "g__" + name
    if pyvar not in translation:
        return
    original_var = original.get(pyvar, [])
    rows = [["index", "value", "comments", "original"]]
    for index, value in enumerate(translation[pyvar]):
        if value is None:
            value = "nil"
        rows.append([index, value, "", access(original_var, index)])

    rows_to_file(output, name, rows)
    del translation[pyvar]


def listdict_to_csv(output, name, translation, original):
    """Write dict of list variable to file"""
    pyvar = "g__" + name
    if pyvar not in translation:
        return
    original_var = original.get(pyvar, {})
    rows = [["key", "index", "value", "comments", "original"]]
    for key, valuelist in translation[pyvar].items():
        ovaluelist = access(original_var, key, [])
        for index, value in enumerate(valuelist):
            rows.append([key, index, value, "", access(ovaluelist, index)])

    rows_to_file(output, name, rows)
    del translation[pyvar]


def main():
    """Main function"""
    parser = argparse.ArgumentParser(description='Convert lang into csv directory')
    parser.add_argument('input', type=str,
                        help='input lang.rb file')
    parser.add_argument('output', type=str,
                        help='output csv directory')
    parser.add_argument('-o', '--original', type=str, default="",
                        help='original lang.rb file (en)')

    args = parser.parse_args()

    translation, header = load_file(args.input)
    original = {}
    if args.original:
        original, _ = load_file(args.original)

    output = Path(args.output)
    output.mkdir(parents=True, exist_ok=True)

    with open(output / "header.txt", "w") as fil:
        fil.write(header)

    vars_to_csv(output, "global_vars", translation, original, "g__", [
        "save_lang",
        "load_lang",
        "time_lang",
        "file_lang",
        "autosave_lang"
    ])
    dict_to_csv(output, "override_fonts_lang", translation, original)
    dict_to_csv(output, "override_images_lang", translation, original)
    list_to_csv(output, "title_lang", translation, original)
    dict_to_csv(output, "menu_lang", translation, original)
    list_to_csv(output, "end_lang", translation, original)
    dict_to_csv(output, "MOM", translation, original)
    dict_to_csv(output, "MOMHINT", translation, original)
    list_to_csv(output, "journal_lang", translation, original)
    events_lang(output, translation, original)
    dict_to_csv(output, "actors_lang", translation, original)
    dict_to_csv(output, "animations_lang", translation, original)
    listdict_to_csv(output, "armors_lang", translation, original)
    dict_to_csv(output, "classes_lang", translation, original)
    dict_to_csv(output, "enemies_lang", translation, original)
    listdict_to_csv(output, "items_lang", translation, original)
    dict_to_csv(output, "mapinfos_lang", translation, original)
    listdict_to_csv(output, "skills_lang", translation, original)
    dict_to_csv(output, "states_lang", translation, original)
    dict_to_csv(output, "system_words", translation, original)
    list_to_csv(output, "system_elements", translation, original)
    dict_to_csv(output, "tilesets_lang", translation, original)
    dict_to_csv(output, "troops_lang", translation, original)
    listdict_to_csv(output, "weapons_lang", translation, original)
    vars_to_csv(output, "variables", translation, original,
                keys=list(translation.keys()))


if __name__ == "__main__":
    main()
