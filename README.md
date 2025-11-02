# Photo Video scripts

Scripts that I use to organize and fix my photo and video collection.

## fix-jpg-dates.sh

Searches for images without clear creation exif fields and uses the directory where they are located (yyyy-mm-dd) to set
the file modification timestamp so most tools will behave properly.

## fix-mp4-metadata.sh

Through trial and error I found out that when using ffmpeg from the command line it's easy
to lose metadata. Luckily I still had the original mp4 files. This script copies the metadata
from the original mp4 files into files that were already cropped and transcoded.

## reduce-images.sh

The name is incorrect: it also reduces mp4s. The script:

- reduces images to a max resolution of 1280 x 720 (HD ready),
- reduces images to a max quality of 80%,
- converts pngs to jpegs,
- reduces mp4s to a max resolution of 1280 x 720,
- transcodes mp4s to H.264.

For me this is good enough to hold on to the memories without having to invest in local and cloud storage.
