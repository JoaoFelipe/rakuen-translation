"""This file calculates the similarity of rows in a csv file"""

import csv
import difflib
import json
import argparse
from tqdm import tqdm
from collections import defaultdict

def calculate_similarity(rows, column, rqr_threshold=0.6, qr_threshold=0.5, r_threshold=0.0):
    """Caculate similarity between a column of rows. Returns a dict"""
    similarity = defaultdict(dict)

    for i in tqdm(range(1, len(rows))):
        for j in range(i + 1, len(rows)):
            ratio = difflib.SequenceMatcher(None, rows[i][column], rows[j][column])
            rqr = ratio.real_quick_ratio()
            if rqr > rqr_threshold:
                qr = ratio.quick_ratio()
                if qr > qr_threshold:
                    r = ratio.ratio()
                    if r > r_threshold:
                        similarity[i][j] = (rqr, qr, r)
                        similarity[j][i] = similarity[i][j]
    return similarity


def include_similarity_to_rows(rows, similarity, column):
    """Add similarity column to rows
    Top 5 similarity
    Top 10 similarity greater than 80% in cells with more than 100 characters

    Close cells with the same similarity rank better
    """
    result = {}
    for key, sims in tqdm(new.items()):
    sort = sorted(list(sims.items()), reverse=True, 
                  key=lambda x: (x[1][-1], -abs(x[0] - key)))
    result[key] = [
        x for i, x in enumerate(sort) 
        if i < 5 
        or (x[1][-1] > 0.8 and len(rows[x[0]][column]) > 100 and i < 10)
    ]
    for key, value in result.items():
        tvalue = "\n".join(
            "{} -> {:.1%}".format(x[0] + 1, x[1][-1])
            for x in value
        )
        rows[key].append(tvalue)
    return rows



def main():
    """Main function"""
    parser = argparse.ArgumentParser(description='Calculate similarity')
    parser.add_argument('input', type=str,
                        help='input csv file')
    parser.add_argument('column', type=int,
                        help='read column from csn')
    parser.add_argument('output', type=str,
                        help='output csv file')
    parser.add_argument('-s', '--sim', type=str, default="",
                        help='save full similarity into json file')
    parser.add_argument('-l', '--load', type=str, default="",
                        help='load full similarity from json file')

    args = parser.parse_args()

    with open(args.input, "r") as fil:
        reader = csv.reader(fil)
        rows = list(reader)

    if args.load:
        with open(args.load, "r") as fil:
            similarity = json.load(fil)
    else:
        similarity = calculate_similarity(rows, args.column)

    if args.sim:
        with open(args.sim, "w") as fil:
            json.dump(similarity, fil)

    rows[0].append("similarity")
    include_similarity_to_rows(rows, similarity, args.column)
    with open(args.output, "w") as fil:
        writer = csv.writer(fil, quoting=csv.QUOTE_NONNUMERIC,
                            lineterminator='\n')
        writer.writerows(rows)
