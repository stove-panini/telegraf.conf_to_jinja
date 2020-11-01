#!/usr/bin/awk -f
BEGIN {
    RS = ""
    FS = "\n"
}

{
    trimmed_front = substr($2, 5)
    trimmed_len = length(trimmed_front) - 2
    filename = substr(trimmed_front, 0, trimmed_len) ".conf"

    # Remove comments. Records in AWK's paragraph mode are treated as one long
    # string with newline characters.
    #gsub(/^# /, "")
    #gsub(/\n# /,"\n")

    print "Writing " filename
    print > "./telegraf.d/" filename
}
