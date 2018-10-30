#!/bin/bash

if [ "$1" == "" ]; then
    echo "Parameter alamat m3u8 tidak ditemukan!";
    exit;
fi

if ! curl --fail  -O -J "$1" --silent; then
    echo "Berkas m3u8 gagal di unduh";
    exit;
fi;

urlm3u8=$1
base=${urlm3u8%/*}
filem3u8=${urlm3u8##*/}
filenamem3u8=${filem3u8%.m3u8}
urlkey=$(grep -o 'URI=".*",' $filem3u8 | sed 's/URI\="//g' | sed 's/",//g');
localkey="$filenamem3u8.key"
urlkeytemp=$(echo "$urlkey" | sed 's/\//\\\//g' | sed 's/\&/\\\&/g');
sed -i "s/$urlkeytemp/$localkey/g" $filem3u8;

echo $localkey;
echo $urlkeytemp;

if ! curl --fail  "$urlkey" --silent -o "$localkey"; then
    echo "Berkas kunci gagal di unduh";
    exit;
fi;

sline="$(grep -vE '^(\s*$|#)' $filem3u8 | wc -l)";
i=1;

while IFS='' read -r line || [[ -n "$line" ]]; do
    echo "Unduh [$i/$sline]: $line";
    (mkdir -p ${line%/*} && cd ${line%/*} && curl -O -J "$base/$line" --silent)
    ((i++))
done <<< "$(grep -vE '^(\s*$|#)' $filem3u8)"

echo "Proses penggabungan file";
ffmpeg -hide_banner -loglevel panic -allowed_extensions ALL -i "$filem3u8" -c copy -bsf:a aac_adtstoasc "$filenamem3u8.mp4"
echo "Selesai.";