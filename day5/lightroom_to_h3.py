import sys

import h3
import sqlite3

def main() -> None:
    lightroom_db_path = sys.argv[1]
    con = sqlite3.connect(lightroom_db_path)
    cur = con.cursor()

    res = dict()
    for lat, lng in cur.execute("select gpsLatitude, gpsLongitude from AgHarvestedExifMetadata where gpsLatitude IS NOT NULL AND gpsLongitude IS NOT NULL"):
        cellid = h3.latlng_to_cell(lat, lng, 3)
        try:
            res[cellid] += 1
        except KeyError:
            res[cellid] = 1

    for key in res:
        print(f"{key}, {res[key]}")

if __name__ == "__main__":
    main()
