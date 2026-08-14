#!/bin/bash
# Open Chrome Web Store pages for extensions that need manual install on Brave.
IDS=(
  fpeoodllldobpkbkabpblcfaogecjfnd  # Wayback Machine
  mdjildafknihdffpkfmmpnpoiajfjnjp  # Consent-O-Matic
  hghfmpfgedilaaifgmifjifcnbmhnjgp  # SteamDB
  cnojnbhfgnonoadidmeapkagrwoliuhd  # Search by Image
  pogrtkgaodjclenpemiijgbmeoftdaai  # Privacy Badger
  hcgoppmnlmbhihgpapikdaebohkmffpa  # Web Archives
  hjjfgaibbnnhjbjjdaoncpnbhfjekndi  # Download All Images
  indlcfdjkggjigbnfllfdllmicpjlche  # Sauce for Strava
)
for id in "${IDS[@]}"; do
  open -a "Brave Browser" "https://chromewebstore.google.com/detail/${id}"
  sleep 0.5
done
echo "Click Add to Brave on each tab."
