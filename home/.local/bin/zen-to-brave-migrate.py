#!/usr/bin/env python3
"""Export Zen Browser profile data for Brave (Chromium) migration."""

from __future__ import annotations

import json
import shutil
import sqlite3
import time
from pathlib import Path

ZEN_PROFILE = Path.home() / ".config/zen/yohsoh2z.Default (release)"
OUT = Path("/tmp/zen-brave-migrate")
PAC_SRC = Path.home() / ".config/omarchy/clash-proxy.pac"

# Firefox add-on id -> Chrome Web Store extension id
CHROME_EXTENSIONS = {
    "uBlock0@raymondhill.net": ("cjpalhdlnbpafiamejdnhcphjbkeiagm", "uBlock Origin"),
    "{446900e4-71c2-419f-a6a7-df9c091e268b}": ("nngceckbapebfimnlniiiahkandclblb", "Bitwarden"),
    "gdpr@cavi.au.dk": ("mdjildafknihdffpkfmmpnpoiajfjnjp", "Consent-O-Matic"),
    "addon@darkreader.org": ("eimadpbcbfnmbkopoojfekhnkhdbieeh", "Dark Reader"),
    "{32af1358-428a-446d-873e-5f8eb5f2a72e}": ("hjjfgaibbnnhjbjjdaoncpnbhfjekndi", "Download All Images"),
    "jid1-MnnxcxisBPnSXQ@jetpack": ("pogrtkgaodjclenpemiijgbmeoftdaai", "Privacy Badger"),
    "{762f9885-5a13-4abd-9c77-433dcd38b8fd}": ("gebbhagfogifgggkldgodflihgfeippi", "Return YouTube Dislike"),
    "{0f1b4c25-4ab0-411e-ba22-e56c27f3d151}": ("indlcfdjkggjigbnfllfdllmicpjlche", "Sauce for Strava"),
    "{2e5ff8c8-32fe-46d0-9fc8-6b8986621f3c}": ("cnojnbhfgnonoadidmeapkagrwoliuhd", "Search by Image"),
    "sponsorBlocker@ajay.app": ("mnjggcdmjocbbbhaepdhchncahnbgone", "SponsorBlock"),
    "firefox-extension@steamdb.info": ("hghfmpfgedilaaifgmifjifcnbmhnjgp", "SteamDB"),
    "{7a7a4a92-a2a0-41d1-9fd7-1e92480d612d}": ("fjnbnpbmkenffdnngjfgmeleoegfcffe", "Stylus"),
    "firefox@tampermonkey.net": ("dhdgffkkebhmkfjojejmpbldmpobfkfo", "Tampermonkey"),
    "vimium-c@gdh1995.cn": ("hfjbmagddngcpeloejdejnfgbamkjaeg", "Vimium C"),
    "wayback_machine@mozilla.org": ("fpeoodllldobpkbkabpblcfaogecjfnd", "Wayback Machine"),
    "{d07ccf11-c0cd-4938-a265-2a4d6ad01189}": ("hcgoppmnlmbhihgpapikdaebohkmffpa", "Web Archives"),
    "snaplinks@snaplinks.mozdev.org": ("mbniclmhobmnbdlbpiphghaielnnpgdp", "Snap Links"),
}

SKIP_FIREFOX_BUILTIN = {
    "userchrome-toggle@joolee.nl",
    "formautofill@mozilla.org",
    "pictureinpicture@mozilla.org",
    "addons-search-detection@mozilla.com",
    "webcompat@mozilla.org",
    "newtab@mozilla.org",
    "data-leak-blocker@mozilla.com",
    "ipp-activator@mozilla.com",
    "jid1-NIfFY2CA8fy1tg@jetpack",  # AdBlock — uBlock covers this
}


def chrome_ts() -> str:
    return str(int(time.time() * 1_000_000))


def export_bookmarks() -> dict:
    src = ZEN_PROFILE / "places.sqlite"
    tmp = OUT / "places.sqlite"
    shutil.copy2(src, tmp)
    conn = sqlite3.connect(f"file:{tmp}?mode=ro", uri=True)
    rows = conn.execute(
        """
        SELECT b.id, b.parent, b.type, COALESCE(b.title, ''), COALESCE(p.url, ''), b.position
        FROM moz_bookmarks b
        LEFT JOIN moz_places p ON b.fk = p.id
        ORDER BY b.parent, b.position
        """
    ).fetchall()
    conn.close()

    nodes: dict[int, dict] = {}
    for bid, parent, typ, title, url, _pos in rows:
        if typ == 1:  # bookmark
            if url.startswith(("chrome-extension:", "about:")):
                continue
            nodes[bid] = {
                "date_added": chrome_ts(),
                "name": title or url,
                "type": "url",
                "url": url,
            }
        elif typ == 2:  # folder
            nodes[bid] = {
                "date_added": chrome_ts(),
                "date_modified": chrome_ts(),
                "name": title or "Folder",
                "type": "folder",
                "children": [],
            }
        elif typ in (3, 5):  # separator / dynamic — skip
            continue

    # Firefox roots: 3=toolbar, 2=menu, 5=unfiled, 6=mobile (all under id 1)
    roots = {3: "bookmark_bar", 2: "other", 5: "other", 6: "synced"}
    chrome_roots = {
        "bookmark_bar": {
            "children": [],
            "date_added": chrome_ts(),
            "date_modified": chrome_ts(),
            "name": "Bookmarks bar",
            "type": "folder",
        },
        "other": {
            "children": [],
            "date_added": chrome_ts(),
            "date_modified": chrome_ts(),
            "name": "Other bookmarks",
            "type": "folder",
        },
        "synced": {
            "children": [],
            "date_added": chrome_ts(),
            "date_modified": chrome_ts(),
            "name": "Mobile bookmarks",
            "type": "folder",
        },
    }

    def attach(parent_id: int, child_id: int) -> None:
        if child_id not in nodes:
            return
        parent_node = nodes.get(parent_id)
        if parent_node and parent_node["type"] == "folder":
            parent_node["children"].append(nodes[child_id])
            return
        root_key = roots.get(parent_id)
        if root_key:
            chrome_roots[root_key]["children"].append(nodes[child_id])

    for bid, parent, typ, _title, _url, _pos in rows:
        if bid in nodes and parent:
            attach(parent, bid)

    # Firefox keeps bookmarks inside toolbar/menu/unfiled/mobile folders
    if 3 in nodes:
        chrome_roots["bookmark_bar"]["children"] = nodes[3]["children"]
    if 2 in nodes:
        chrome_roots["other"]["children"].extend(nodes[2]["children"])
    if 5 in nodes:
        chrome_roots["other"]["children"].extend(nodes[5]["children"])
    if 6 in nodes:
        chrome_roots["synced"]["children"] = nodes[6]["children"]

    return {"checksum": "", "roots": chrome_roots, "version": 1}


def export_extensions_manifest() -> list[dict]:
    data = json.loads((ZEN_PROFILE / "extensions.json").read_text())
    installed = []
    for addon in data.get("addons", []):
        if addon.get("type") != "extension":
            continue
        fid = addon["id"]
        if fid in SKIP_FIREFOX_BUILTIN:
            continue
        if fid not in CHROME_EXTENSIONS:
            continue
        if not addon.get("active") or addon.get("userDisabled"):
            continue
        chrome_id, name = CHROME_EXTENSIONS[fid]
        installed.append({"firefox_id": fid, "chrome_id": chrome_id, "name": name})
    return installed


def brave_preferences_patch(mac_user: str) -> dict:
    pac = f"file:///Users/{mac_user}/.config/omarchy/clash-proxy.pac"
    return {
        "browser": {
            "theme": {
                "color_scheme": 2,  # dark
                "color_scheme2": 2,
            },
            "custom_chrome_frame": False,
            "window_placement": {},
        },
        "dns_over_https": {"mode": "automatic"},
        "enable_do_not_track": True,
        "extensions": {
            "ui": {"developer_mode": False},
        },
        "homepage": "chrome://newtab/",
        "homepage_is_newtabpage": True,
        "net": {
            "network_prediction_options": 2,
        },
        "profile": {
            "content_settings": {
                "exceptions": {
                    "geolocation": {
                        "https://www.strava.com:443,*": {"setting": 1},
                        "https://strava.com:443,*": {"setting": 1},
                    }
                }
            },
            "default_content_setting_values": {"geolocation": 1},
        },
        "proxy": {
            "mode": "pac_script",
            "pac_url": pac,
        },
        "safebrowsing": {"enabled": True},
        "session": {
            "restore_on_startup": 1,
            "startup_urls": [],
        },
        "sync": {"requested": False},
    }


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "extensions").mkdir(exist_ok=True)

    bookmarks = export_bookmarks()
    (OUT / "Bookmarks").write_text(json.dumps(bookmarks, indent=2))

    ext_list = export_extensions_manifest()
    (OUT / "extensions.json").write_text(json.dumps(ext_list, indent=2))

    for item in ext_list:
        cid = item["chrome_id"]
        (OUT / "extensions" / f"{cid}.json").write_text(
            json.dumps({"external_update_url": "https://clients2.google.com/service/update2/crx"}, indent=2)
            + "\n"
        )

    # PAC for Mac (same logic, Mac path in deploy script)
    if PAC_SRC.exists():
        pac = PAC_SRC.read_text()
        (OUT / "clash-proxy.pac").write_text(pac)

    prefs = brave_preferences_patch("zzx")
    (OUT / "brave_prefs_patch.json").write_text(json.dumps(prefs, indent=2))

    # Export bookmark HTML fallback
    html_lines = ["<!DOCTYPE NETSCAPE-Bookmark-file-1>", "<META HTTP-EQUIV=\"Content-Type\" CONTENT=\"text/html; charset=UTF-8\">", "<TITLE>Bookmarks</TITLE>", "<H1>Bookmarks</H1>", "<DL><p>"]

    def walk_html(node: dict, depth: int = 0) -> None:
        if node.get("type") == "url":
            html_lines.append(f'    <DT><A HREF="{node["url"]}">{node["name"]}</A>')
        elif node.get("type") == "folder":
            html_lines.append(f'    <DT><H3>{node["name"]}</H3>')
            html_lines.append("    <DL><p>")
            for child in node.get("children", []):
                walk_html(child, depth + 1)
            html_lines.append("    </DL><p>")

    for child in bookmarks["roots"]["bookmark_bar"]["children"]:
        walk_html(child)
    for child in bookmarks["roots"]["other"]["children"]:
        walk_html(child)
    html_lines.append("</DL><p>")
    (OUT / "bookmarks.html").write_text("\n".join(html_lines))

    print(f"Exported to {OUT}")
    print(f"  Bookmarks: {sum(1 for _ in open(OUT/'Bookmarks'))} lines JSON")
    print(f"  Extensions: {len(ext_list)}")
    for e in ext_list:
        print(f"    - {e['name']}")


if __name__ == "__main__":
    main()
