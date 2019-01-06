#!/usr/bin/env python2
 # -*- coding: utf-8 -*-
'''
Computes number of words in a translation file provided
@author Ph4r05
'''
import re
import os
import sys
import argparse
import traceback
import datetime
import unicodedata
import codecs
import locale

# pip install chardet
import chardet

def computeFile(fname):
    numChars = 0
    numKeys = 0
    keys=[]
    text=[]
    pattern = re.compile(ur"""[^\"“]*\s*[\"“](.*?)[\"“]\s*=\s*[\"“](.*?)[\"“]\s*;[\s\n\r\t]*""", re.UNICODE | re.IGNORECASE | re.DOTALL)

    detection = chardet.detect(open(fname).read())
    with codecs.open(fname, 'r', encoding=detection['encoding']) as f:
        content = f.readlines()
        for line in content:
            line = line.strip().rstrip()

            if len(line) == 0 or line.startswith("#"):
                continue

            match = pattern.match(line)
            if match is None:
                print u"Does not match!! [%s]" % line
                continue

            numKeys+=1
            curKey = match.group(1)
            curTxt = match.group(2)

            numChars+=len(curTxt)
            keys.append(curKey)
            text.append(curTxt)

    return (numChars, numKeys, keys, text, detection['encoding'])

# Main executable code
if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Word count compute', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('file', metavar='file', nargs='+', help='file to compute')
    parser.add_argument('--text', help='Dump only text values', default=0, type=int, required=False)
    parser.add_argument('--keys', help='Dump only key values', default=0, type=int, required=False)

    args = parser.parse_args()
    if args.file is None or len(args.file) == 0:
        parser.print_help()
        sys.exit(-1)

    dispText = args.text > 0
    dispKeys = args.keys > 0

    # Wrap sys.stdout into a StreamWriter to allow writing unicode.
    sys.stdout = codecs.getwriter(locale.getpreferredencoding())(sys.stdout)

    for curfile in args.file:
        (numChars, numKeys, keys, text, encoding) = computeFile(curfile)
        if not dispKeys and not dispText:
            print "Character compute for file %s" % (curfile)
            print " Char count: %s = %s NS" % (numChars, numChars/1800.0)
            print " Number of keys: %s" % (numKeys)
            print ""
        if dispKeys:
            for k in keys:
                print k
        if dispText:
            print text[2]
            for t in text:
                print t
