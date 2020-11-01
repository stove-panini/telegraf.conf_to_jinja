#!/usr/bin/awk -f

function last(array,sep,    arrayElements, totalIndices)
{
    totalIndices = split(array, arrayElements, sep)
    return arrayElements[totalIndices]
}

function trimLastChar(string,    len)
{
    len = length(string)
    return substr(string, 1, len - 1)
}

function isOption(record)
{
    if (record ~ /^ *##/ || record ~ /,$/ || NF <= 1)
        return 0
    else
        return 1
}

function isSubsection(field)
{
    # [foo], not [[foo]]
    if (field ~ /[^\[]\[([^\[\]]+)\][^\]]?$/ && field !~ /=/) {
        return 1
    } else {
        return 0
    }
}

function getComment(field)
{
    if (field ~ /^ +# /) {
        return "#"
    } else {
        return ""
    }
}

function getKey(field)
{
    switch (field) {
    # Uncommented variables
    case /^  [a-z]/:
        return substr(field, 3)
        break
    # Indented further into subsection
    case /^    [a-z]/:
        return substr(field, 5)
        break
    # Commented variables
    case /^  # [a-z]/:
        return substr(field, 5)
        break
    case /^  #[a-z]/:
        return substr(field, 4)
        break
    # There are several styles of commenting subsection vars in the config
    case /^[ #]{6}[a-z]/:
        return substr(field, 7)
        break
    default:
        print "Unable to determine key. Got:"
        print field
        exit 1
    }
}

function getValueType(value)
{
    switch (value) {
    case /^\"/:
        return "string"
        break
    case /^\[/:
        return "array"
        break
    case /^\{/:
        return "hash"
        break
    case /^(true|false)$/:
        return "boolean"
        break
    case /^-?[0-9]+(\.)?([0-9]+)?$/:
        return "number"
        break
    default:
        print "Unable to determine value type. Got:"
        print value
        exit 1
    }
}

function getYAMLValue (value, type,    formatted)
{
    switch (type) {
    case /(string|number)/:
        return value
        break
    case "array":
        # If we have an array split into multiple lines
        if (value !~ /\]/) {
            # I don't have time for this
            print YAMLVar " will need some manual intervention"
            return "[]"
        } else {
            return value
        }
        break
    case "hash":
        # If we have a hash split into multiple lines
        if (Value !~ /\}/) {
            # I don't have time for this
            print YAMLVar " will need some manual intervention"
            return "{}"
        } else {
            formatted = value
            gsub(/"/, "", formatted)
            gsub(/ = /, ": ", formatted)
            return formatted
        }
        break
    case "boolean":
        if (value ~ /[Tt]rue/ ) {
            return "yes"
        }
        if (value ~ /[Ff]alse/ ) {
            return "no"
        }
        break
    default:
        print "Unable to sanitize value for yaml."
        print "Type: " type
        print "Value: " value
        exit 1
    }
}

BEGIN {
    Filename = last(ARGV[1], "/")

    split(Filename, FilenameElements, ".")
    PluginCategory = FilenameElements[1]
    PluginName = FilenameElements[2]

    VarPrefix = "telegraf_" PluginCategory "_" PluginName "_"
    YAMLFile = PluginCategory "." PluginName ".yml"

    FS = " = "
    print "--------------------"
    print "Processing " Filename
    print "===================="
}

{
    # Remove leading comments
    sub(/^# ?/, "")

    # Subsection
    if (isSubsection($1)) {
        print $0 > "./templates/" Filename ".j2"
        Subsection = trimLastChar(last($1, ".")) "_"
        SubsectionIndent = "  "
        next
    }

    # Skip processing and just copy the line to our template
    if (! isOption($0)) {
        print $0 > "./templates/" Filename ".j2"
        next
    }

    Comment = getComment($1)
    Key = getKey($1)
    Value = $0
    sub($1 FS, "", Value)
    Type = getValueType(Value)
    YAMLVar = VarPrefix Subsection Key
    YAMLValue = getYAMLValue(Value, Type)

    # Write to Ansible vars YAML
    #print Comment YAMLVar ": " YAMLValue
    print Comment VarPrefix Subsection Key ": " YAMLValue > "./vars/" YAMLFile

    # Build Jinja elements
    if (Comment) {
        JinjaComment = "{{ '#' if " YAMLVar " is not defined else '' }}"
    } else {
        JinjaComment = ""
    }

    switch (Type) {
    case "string":
        JinjaValue = "\"{{ " YAMLVar "|d() }}\""
        break
    case "number":
        JinjaValue = "{{ " YAMLVar "|d() }}"
        break
    case "array":
        JinjaValue = "[ {% for i in " YAMLVar "|d([]) %}\"{{ i }}\"{{ ', ' if not loop.last else '' }}{% endfor %} ]"
        break
    case "hash":
        JinjaValue = "{ {% for k, v in (" YAMLVar "|d({})).items() %}\"{{ k }}\" = \"{{ v }}\"{{ ', ' if not loop.last }}{% endfor %} }"
        break
    case "boolean":
        JinjaValue = "{{ " YAMLVar "|d()|bool|lower }}"
        break
    default:
        print "FUCK!!!1"
    }

    print "  " SubsectionIndent JinjaComment Key " = " JinjaValue > "./templates/" Filename ".j2"
}
