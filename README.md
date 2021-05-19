# Czruby - easy Ruby version management for Z-Shell

**czruby** | tʃeɪn(d)ʒˈruːbi |  
**noun**  
1 **an app or plugin for Z-shell or (less formerly) zsh, that is partly descended from [chruby](https://github.com/postmodern/chruby).**

**verb**  
1 *[with object, with complement]* **make [Ruby](https://www.ruby-lang.org/en/) or its related environment change or become different:**: *please change to the system Ruby instead*

ORIGIN  
------  
mid 21st century: phonologically Polish portmanteu of ***chruby*** and ***Z-shell***.

## Usage

`czruby 3.0.0` will change to Ruby v3.0.0

`czruby truffleruby` will change (on my system) to TruffleRuby v21.1.0 because I only have one version of TruffleRuby. If I had more it would show an error.

`czruby truffleruby-21.1.0` would then be the correct command to use (I could use that anyway)

Help is available via `czruby -h`.

`czruby --set-default 2.7.0` would set the default ruby, temporarily, to Ruby v2.7.0 and change to it. It's only temporary because you'll probably set the default ruby via `RUBIES_DEFAULT` in your `~/.zshenv`.

`czruby` with no arguments will show you:

- all the installed rubies it knows about
- all their paths
- the currently selected ruby
- the default ruby
- the system ruby



## Dependencies

- Z-shell
- Use of [XDG](https://specifications.freedesktop.org/basedir-spec/latest/ar01s02.html) environment variables

## Install

It only needs to be `source`d, so put it wherever is convenient for doing so (probably loaded by zshrc).

## Setup and things you should know

First, set the `XDG_CONFIG_HOME`, `XDG_CACHE_HOME` and `XDG_DATA_HOME` environment variables. I have mine set in `~/.zshenv` as follows:

```shell
export XDG_CONFIG_HOME="${HOME}/Library/Application Support"
export XDG_DATA_HOME="$XDG_CONFIG_HOME"
export XDG_CACHE_HOME="$HOME/Library/Caches"
```

You don't have to do that, it's just an example.

The `RUBIES_DEFAULT` environment variable tells czruby which Ruby version to use as default. If you don't set it then the default default is `system`, which on a Mac is v2.3.7. (You can also set it temporarily, more on that later).

The `RUBIES` environment variable holds the paths of installed rubies. If you want to add one then this is the kind of thing you might do:

```shell
rubies=(path/to/ruby/containing/the/bin/dir $rubies)
```

For example, given this:

```shell
$ tree -L 1 ~/.rubies/2.7.0
/Users/iainb/.rubies/2.7.0
├── bin
├── include
├── lib
└── share
```

then this would be the real command:

```shell
rubies=("$HOME/.rubies/2.7.0" $rubies)
```

So, you can add rubies installed from anywhere. Since you'll probably want to do this on shell init there is help in the form of the `czruby_custom_init`. Czruby will call it (if defined) during its init phase of your shell (or whenever else you source the czruby file).

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

I use [GNU readlink](http://www.gnu.org/software/coreutils/manual/html_node/readlink-invocation.html) (because the Mac version isn't really up to snuff) to make sure that symbolic links are handled properly. (It can be installed via the coreutils package, [Macports](https://www.macports.org/) and [pkgsrc](https://pkgsrc.joyent.com/install-on-osx/) have it, homebrew surely does too).

## How does it work?

Good question!

During czruby's init phase it will write some files to `$XDG_DATA_HOME/czruby` (which is why you should set those XDG vars). Here's the one it wrote for my `system` ruby:

```shell
export RUBY_ENGINE="ruby"
export RUBY_ROOT="/usr"
export RUBY_VERSION="2.3.7"
export GEM_HOME=$(gem_calc_home)
gem_path=($GEM_HOME "/usr/lib/ruby/gems/2.3.7" $gem_path)
path=("$RUBY_ROOT/bin" $path)
local bin
for place in ${(Oa)gem_path}; do
  bin="$place/bin"
    path=("$bin" $path)
done
unset bin
```

Then, when you ask for a different Ruby, it simply sources the file associated with the Ruby.

- It removes all the current Ruby's environment, removes bits from `PATH` etc
- It sets up the `PATH` with installed gem executables first, then the gems installed with Ruby, then Ruby's bin directory.
- It sets up the `GEM_HOME` env var to be in `$XDG_CACHE_HOME/Ruby`.
- It sets up the `GEM_PATH` properly too.

You also get some helpful env vars set:

- `RUBY_ROOT` e.g. `~/.rubies/2.6.3`
- `RUBY_ENGINE` e.g. ruby or jruby etc
- `RUBY_VERSION` e.g. 2.6.3
- `RUBIES_DEFAULT` e.g. 2.7.0
- `RUBIES`, which will list all the Ruby roots

and these helpful zsh arrays (which you probably won't use but it's good to know they're there) :

- `$gem_path`
- `$rubies`

## What doesn't it do?

It doesn't automatically change to a ruby when entering a directory with a .ruby-version file or anything like that. I'm not really interested in that - use Vagrant or Docker or something like that, the version file is a solution for a problem that (should) no longer persist.

## Why not chruby?

I like chruby the best of all the version managers but it's taking an *age* to get a new release and I get the dreaded [Ignoring gem… because its extensions are not built](https://stackoverflow.com/questions/38797458/ignoring-gem-because-its-extensions-are-not-built) error and nothing fixes it other than not using chruby.

Also, I wanted to have it fit my set up better, and it does.

## So that's that

If you find this useful or think it can be improved, do let me know, I'm open to suggestions. This does, however, work well for me and my setup.

## Licence

See Licence.txt
