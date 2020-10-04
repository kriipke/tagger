# tagger

`tagger` is a command-line utility for tagging files for easy organization, searching, etc. It is POSIX compliant and is effectively a wrapper for the commands `getfattr` and `setfattr`. Enjoy!

```
Usage: tag key[:value] file...
       tag {-d key} file...
       tag {-t key[:value]} [-v] [path...]
       tag {-v} [key] path...

  -d, --delete=key        delete key from file attributes 
  -t, --tagged=key        lists files with tagged with key
      --tagged=key:value  lists files with with tag key whose value is value
  -v, --values            list values, for use with -l
      --null=\"string\"   string to use with -v when key has no value
      --help              this help text
```
