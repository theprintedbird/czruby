# Czruby - easy Ruby version management for Z-Shell

**Czruby** | tʃeɪn(d)ʒˈruːbi |  
**noun**  
1 **an app or plugin for Z-shell or (less formerly) zsh, that is partly descended from [chruby](https://github.com/postmodern/chruby).**

**verb**  
1 *[with object, with complement]* **make [Ruby](https://www.ruby-lang.org/en/) or its related environment change or become different:**: *please change to the system Ruby instead*

ORIGIN  
------  
mid 21st century: phonologically Polish portmanteu of ***chruby*** and ***Z-shell***.

## Dependencies

- Z-shell
- Use of XDG environment variables

## Install

It only needs to be `source`d, so put it wherever is convenient for doing so (probably loaded by zshrc).

## Setup and things you should know

Help is available via `czruby -h`

The `RUBIES_DEFAULT` environment variable tells czruby which Ruby version to use as default. The default default is `system`, which on a Mac is v2.3.7.

The `RUBIES` environment variable holds the paths of installed rubies. If you want to add one then this is the kind of thing you might do:

```shell
rubies=(path/to/ruby/containing/the/bin/dir $rubies)
```

So you can add rubies installed from anywhere. Because you'll probably want to do this on shell init there is help in the form of the `czruby_custom_init`. Czruby will call it (if defined) during its init phase of your shell (or whenever else you source it).

### An example

Let's imagine you've got all your rubies installed in `~/.rubies`:

```
$ tree -L 1 ~/.rubies
~/.rubies
├── 2.5.0
├── 2.5.1
├── 2.6.0
├── 2.6.2
├── 2.6.3
├── 2.7.0
├── jruby-9.1.16.0
└── truffleruby-21.1.0
```

I put this in my `~/.zshenv`:

```shell
export RUBIES_DEFAULT="2.7.0"

czruby_custom_init(){
	for name in $HOME/.rubies/*; do
		rubies=("$name" $rubies)
	done
}
```

Then if I run `czruby`:

```
$ czruby
      | engine     | version   | root
========================================
    *  ruby         2.3.7       /usr
       truffleruby  21.1.0      ~/.rubies/truffleruby-21.1.0
       jruby        9.1.16.0    ~/.rubies/jruby-9.1.16.0
* *    ruby         2.7.0       ~/.rubies/2.7.0
       ruby         2.6.3       ~/.rubies/2.6.3
       ruby         2.6.2       ~/.rubies/2.6.2
       ruby         2.6.0       ~/.rubies/2.6.0
       ruby         2.5.1       ~/.rubies/2.5.1
       ruby         2.5.0       ~/.rubies/2.5.0

current default system
```

or in colour:

![Screenshot of chruby detailing the current status and availability of rubies](https://user-images.githubusercontent.com/326444/118755033-ac75d100-b857-11eb-80e2-b4073806cdae.png)


I actually keep my rubies in `~/Library/Frameworks/Ruby.framework` because Apple have a [useful specification](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPFrameworks/Concepts/FrameworkAnatomy.html) that is organised a lot like [GNU Stow](https://www.gnu.org/software/stow/manual/stow.html) (another useful app). This means my `~/.zshenv` has this:


```shell
czruby_custom_init(){
	for name in $HOME/Library/Frameworks/Ruby.framework/Versions/*; do
		canon=$(greadlink -f "$name")
		if [[ ${canon:t} != "Current" ]]; then
			rubies=("$canon" $rubies)
		fi
	done
}
```

I use GNU readlink (because the Mac version isn't really up to snuff) to make sure that symbolic links are handled properly.

## So that's that

If you find this useful or think it can be improved, do let me know, I'm open to suggestions. This does, however, work well for me and my setup.

## Licence

See Licence.txt
