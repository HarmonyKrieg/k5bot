#!/usr/bin/env sh
# This file is part of the K5 bot project.
# See files README.md and COPYING for copyright and licensing information.
curl http://ftp.monash.edu.au/pub/nihongo/kanjidic2.xml.gz | gunzip > kanjidic2.xml
curl http://ftp.monash.edu.au/pub/nihongo/kradfile-u.gz | gunzip > kradfile-u
curl http://ck.kolivas.org/Japanese/sorted_freq_list.txt > gsf.txt
