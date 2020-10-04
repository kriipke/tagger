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

## usage

You can either use the `tag` command to add:
 - a one dimensional tag, i.e. a label, like "script" or "myproject"
 - a two dimensional tag, i.e. a key/value pair, such as "configuration: networking" or "media: video"

### adding and deleting tags

To add a simple tag like "script" to a file, say `installer.sh`, run:

    tag script installer.sh

To add a key/value pair to a file, run:

    tag script:sh installer.sh

To delete a tag (or a key/value pair) run:

    tag -d script installer.sh

### querying and searching for tags 

If `tag` just receives a single argument then that argument is treated as a path and `tag` will recursively search it for any user extended attributes, and produce a table like this one:

```
$ tag /etc
TAG         FILE

network     /etc/nsswitch.conf
network     /etc/hosts
email       /etc/dnf/automatic.conf
email       /etc/rkhunter.conf
keybindings /etc/tmux/tmux.map
keybindings /etc/keybindings
config      /etc/asound.conf
config      /etc/irssi.conf
config      /etc/profile.d
config      /etc/bashrc.d
```

The `-v` switch will show the values associated with any tags as well:

```
$ tag -v /etc
TAG         VALUE       FILE
network     nss         /etc/nsswitch.conf
network     dns         /etc/hosts
email                   /etc/dnf/automatic.conf
email                   /etc/rkhunter.conf
keybindings tmux        /etc/tmux/tmux.map
keybindings             /etc/keybindings
config      alsa        /etc/asound.conf
config      irssi       /etc/irssi.conf
config      shell       /etc/profile.d
config      shell       /etc/bashrc.d
```


To query for files with particular tags you can use:

    tag -t config /etc

or for files with a particular key/value tag:

    tag -t config:shell /etc
