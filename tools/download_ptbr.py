import argparse
import requests
from pathlib import Path
import zipfile
import shutil

from tqdm import tqdm

from csv_to_lang import csv_to_lang

NAME = "Portuguese - Português do Brasil"
DRIVE = [
    {'name': 'actors_lang.csv',
     'url': 'https://docs.google.com/spreadsheets/d/18TBi0wh748jvOpBw60WN2UflWC2UzDlfL602ZKDKLbQ/gviz/tq?tqx=out:csv&sheet=actors_lang.csv'},
    {'name': 'animations_lang.csv',
     'url': 'https://docs.google.com/spreadsheets/d/180bwVODKD21O1bL_tXtDhehCJfn1HdFjAjk7mNDkrU8/gviz/tq?tqx=out:csv&sheet=animations_lang.csv'},
    {'name': 'armors_lang.csv',
     'url': 'https://docs.google.com/spreadsheets/d/13mjlONYAOeR7y_EwK2oyJfYXZ9bfMbeE63VC-5Y09-s/gviz/tq?tqx=out:csv&sheet=armors_lang.csv'},
    {'name': 'classes_lang.csv',
     'url': 'https://docs.google.com/spreadsheets/d/1IES_lTa_BYIFgG70PwARnQ5omamEdFkyF-KvaBgp-tw/gviz/tq?tqx=out:csv&sheet=classes_lang.csv'},
    {'name': 'end_lang.csv',
     'url': 'https://docs.google.com/spreadsheets/d/1Duf_ymNDpSwM3OifiVHO57snjA4QgwaUB34Z9xlQ1-8/gviz/tq?tqx=out:csv&sheet=end_lang.csv'},
    {'name': 'enemies_lang.csv',
     'url': 'https://docs.google.com/spreadsheets/d/1ajeC7vzy9uWX2NfVWfkvFLHLr_GNZiDoXJKeLApdeQg/gviz/tq?tqx=out:csv&sheet=enemies_lang.csv'},
    {'name': 'events_lang.csv',
     'url': 'https://docs.google.com/spreadsheets/d/1gt4lcxbbfPpm9dbZwrplAH1l03pGINRaoDvrvNt-X74/gviz/tq?tqx=out:csv&sheet=events_lang.csv'},
    {'name': 'global_vars.csv',
     'url': 'https://docs.google.com/spreadsheets/d/1aw8uf569nxZzpxANtwmNQZN41CX3Nzje6HT0hSNVqF0/gviz/tq?tqx=out:csv&sheet=global_vars.csv'},
    {'name': 'items_lang.csv',
     'url': 'https://docs.google.com/spreadsheets/d/1aGWM0rwWn1KX4uJln10BryUZlI612T4qSr-aNAYQ5Hs/gviz/tq?tqx=out:csv&sheet=items_lang.csv'},
    {'name': 'journal_lang.csv',
     'url': 'https://docs.google.com/spreadsheets/d/1gKqWeOtrG6UT8B7ABbcczZp6gHCiHQg84y-kj7THez0/gviz/tq?tqx=out:csv&sheet=journal_lang.csv'},
    {'name': 'mapinfos_lang.csv',
     'url': 'https://docs.google.com/spreadsheets/d/1T0OIxb9Vopai0fNhLHF4ti1a98QV5ZT9EtJEo9749T0/gviz/tq?tqx=out:csv&sheet=mapinfos_lang.csv'},
    {'name': 'menu_lang.csv',
     'url': 'https://docs.google.com/spreadsheets/d/1SxbyrmBAOhFVXmfxUXKehoiz3nJ9iZDnA0ayCULZ1KI/gviz/tq?tqx=out:csv&sheet=menu_lang.csv'},
    {'name': 'MOM.csv',
     'url': 'https://docs.google.com/spreadsheets/d/13cBXTaNwtipoWkiuLr84j-zLwRmH-f-rHXRvVUZTbjM/gviz/tq?tqx=out:csv&sheet=MOM.csv'},
    {'name': 'MOMHINT.csv',
     'url': 'https://docs.google.com/spreadsheets/d/1cj1uCqersiPw1dO05qO_0KjKyA2ucNiWkt72mvZu5q8/gviz/tq?tqx=out:csv&sheet=MOMHINT.csv'},
    {'name': 'override_fonts_lang.csv',
     'url': 'https://docs.google.com/spreadsheets/d/1P2JRTn-sIyloxbm6ojv8rraQpA7HE38CW5uBlIfYFcY/gviz/tq?tqx=out:csv&sheet=override_fonts_lang.csv'},
    {'name': 'override_images_lang.csv',
     'url': 'https://docs.google.com/spreadsheets/d/1-uT9ExKy8u95_xXYdO1UytWTRi8EoTuslHl3hZoiN04/gviz/tq?tqx=out:csv&sheet=override_images_lang.csv'},
    {'name': 'skills_lang.csv',
     'url': 'https://docs.google.com/spreadsheets/d/1Jv9HH1VhDA6jExMO-SgYATPTUGDYTLxZ3ffoNC7niMM/gviz/tq?tqx=out:csv&sheet=skills_lang.csv'},
    {'name': 'states_lang.csv',
     'url': 'https://docs.google.com/spreadsheets/d/1WTCOFLMXvheigTcPimmRE5UVXPexPFu6L5dUZywn5_k/gviz/tq?tqx=out:csv&sheet=states_lang.csv'},
    {'name': 'system_elements.csv',
     'url': 'https://docs.google.com/spreadsheets/d/19lCM-77hbpfqn0wUnLeFtDotIhID820zgTnCPSvXCBg/gviz/tq?tqx=out:csv&sheet=system_elements.csv'},
    {'name': 'system_words.csv',
     'url': 'https://docs.google.com/spreadsheets/d/1AcoLoff4VFnfdYm7HwnknH-2tvp3Gi4Ow4HUzKNd584/gviz/tq?tqx=out:csv&sheet=system_words.csv'},
    {'name': 'tilesets_lang.csv',
     'url': 'https://docs.google.com/spreadsheets/d/1O5jGWLxbZfFK3H9m6UhfRVnFqN1ig52gNyd_cRiZwR0/gviz/tq?tqx=out:csv&sheet=tilesets_lang.csv'},
    {'name': 'title_lang.csv',
     'url': 'https://docs.google.com/spreadsheets/d/17WTbHsc5ME4D-mmoSw_AijeCkFWhXv5faT2EXutyXRQ/gviz/tq?tqx=out:csv&sheet=title_lang.csv'},
    {'name': 'troops_lang.csv',
     'url': 'https://docs.google.com/spreadsheets/d/1Xj72kKjOSf1GpNYtT6ZnpbKFWqJNK7UpJvIjIi2Xbf0/gviz/tq?tqx=out:csv&sheet=troops_lang.csv'},
    {'name': 'variables.csv',
     'url': 'https://docs.google.com/spreadsheets/d/1Azxp286Uf4PHuKQGl9p-imYPt-WtEpbeL_JsGQyAhJ8/gviz/tq?tqx=out:csv&sheet=variables.csv'},
    {'name': 'weapons_lang.csv',
     'url': 'https://docs.google.com/spreadsheets/d/1MXXoHS__zoM3g4pU5csCNGyoLX-s5OMWGOHGJJzr28g/gviz/tq?tqx=out:csv&sheet=weapons_lang.csv'},
    {'name': 'header.txt',
     'url': 'https://docs.google.com/document/d/1EJlOZ-UmUwlzArYsvEd1l0GO1G9FGKJkmpYLKE4RGF8/export?format=txt'}
]

LATEST_GRAPHICS = "1HsX_FafSx-W4reHe8Sjf4F9Ygs3c0gFw"

def download_file_from_google_drive(id, destination):
    """FROM https://stackoverflow.com/questions/25010369/wget-curl-large-file-from-google-drive#comment43929971_25033499"""
    def get_confirm_token(response):
        for key, value in response.cookies.items():
            if key.startswith('download_warning'):
                return value

        return None

    def save_response_content(response, destination):
        CHUNK_SIZE = 32768

        with open(destination, "wb") as f:
            for chunk in response.iter_content(CHUNK_SIZE):
                if chunk: # filter out keep-alive new chunks
                    f.write(chunk)

    URL = "https://docs.google.com/uc?export=download"

    session = requests.Session()

    response = session.get(URL, params = { 'id' : id }, stream = True)
    token = get_confirm_token(response)

    if token:
        params = { 'id' : id, 'confirm' : token }
        response = session.get(URL, params = params, stream = True)

    save_response_content(response, destination)


def download(temp_path, data):
    response = requests.get(data['url'], stream=True)
    if response.status_code == 200:
        with open(temp_path / data['name'], 'w', encoding="utf-8") as fil:
            fil.write(response.text.replace("\ufeff", ""))


def main():
    """Main function"""
    parser = argparse.ArgumentParser(description='Download ptbr translation from Google Drive')
    parser.add_argument('-t', '--temp', type=str, default="temp",
                        help='temporary directory')
    parser.add_argument('-o', '--output', type=str, default="../mods/translation/ptbr",
                        help='output ptbr directory')

    args = parser.parse_args()

    tempdir = Path(args.temp)
    tempdir.mkdir(parents=True, exist_ok=True)
    pbar = tqdm(DRIVE)
    for metadata in pbar:
        pbar.set_description(metadata['name'])
        download(tempdir, metadata)

    download_file_from_google_drive(LATEST_GRAPHICS, tempdir / "graphics.zip")


    outputdir = Path(args.output)
    outputdir.mkdir(parents=True, exist_ok=True)

    csv_to_lang(tempdir, outputdir / "lang.rb", final=True)

    with open(outputdir / "name.txt", 'w') as fil:
        fil.write(NAME)

    zip_ref = zipfile.ZipFile(str(tempdir / "graphics.zip"), 'r')
    zip_ref.extractall(outputdir)
    zip_ref.close()

    shutil.rmtree(str(tempdir), True)

if __name__ == "__main__":
    main()
