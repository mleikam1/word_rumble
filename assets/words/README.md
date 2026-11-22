# Word Guess dictionary

`enable_five.txt` contains all five-letter ASCII entries from the public-domain
ENABLE2K word list by Alan Beale and M. Cooper. It is used offline to validate
submitted guesses. The shorter list of possible answers lives in
`lib/data/guess_words.dart`.

The source is [enable2k.txt.gz](https://github.com/BartMassey/wordlists/blob/af52415c13af809bd8757a40f17f46e79d09583c/enable2k.txt.gz).
To reproduce the asset, decompress it, keep lines matching `^[a-z]{5}$`, convert
to uppercase, and write the sorted unique entries, one per line.
See the authors’ [word-list notes and public-domain dedication](https://github.com/BartMassey/wordlists/blob/af52415c13af809bd8757a40f17f46e79d09583c/README-enable2k.txt).
