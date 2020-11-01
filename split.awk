#!/usr/bin/awk -f
BEGIN {
    RS = ""
    FS = "\n"
}

{
    TrimmedFront = substr($2, 5)
    TrimmedLen = length(TrimmedFront) - 2
    Filename = substr(TrimmedFront, 0, TrimmedLen) ".conf"

    print "Writing " Filename
    print > "./telegraf.d/" Filename
}
