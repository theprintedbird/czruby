## Change Ruby

## This Zsh script is designed to manage different Ruby environments. It allows the user to switch
## between various Ruby versions and sets up environment variables for Ruby and Gem paths.

# Note: `rehash` isn't needed because any change to
# $path will trigger an automatic rehash.

# TODO dependency check for greadlink and XDGs are set

# Sets up an array to store the paths of the different Ruby versions.
export -TU RUBIES rubies

# Sets up an array to store the paths for the Gems associated with different Ruby versions.
export -TU GEM_PATH gem_path

# Defines the directory to store configuration files for different Ruby versions.
czruby_datadir="$XDG_DATA_HOME/czruby"


# Calculates and sets up a cache directory for Gems based on the Ruby version and engine being used.
# It ensures the directory exists and returns the path to be used by other functions.
gem_calc_home(){
	local gh="$XDG_CACHE_HOME/Ruby/$RUBY_ENGINE/$RUBY_VERSION"
	mkdir -p "$gh"
	print -n "$gh"
}


# Sets up the environment for managing Ruby versions. It creates necessary directories,
# includes user customizations, and ensures that 'system' Ruby is available in the list.
czruby_setup(){
	mkdir -p "$czruby_datadir"
	if whence -w czruby_custom_init 2>&1 > /dev/null; then
		czruby_custom_init
	fi
	# If system is not found in the rubies then add it
	if ! (( $rubies[(Ie)system] )); then
		rubies=(system $rubies)
	fi
	local ruby_root ruby_ver ruby_eng key
	for ruby_root in $rubies; do
		key="${ruby_root:t}"
		# TODO consider case statement here, for performance
		if [[ $key == system ]]; then
			ruby_root="/usr"
			ruby_eng="ruby"
			ruby_ver="2.3.7" # TODO remove hardcoding
		elif [[ $key =~ "-" ]]; then
			ruby_eng=${key:-ruby}
			splits=(${(s[-])ruby_eng});
			ruby_eng=$splits[1]
			ruby_ver=$splits[2]
		else
			ruby_eng="ruby"
			ruby_ver="$key"
		fi

		# Writes environment setup for the specific Ruby version.
cat << EOF > "$czruby_datadir/$key"
export RUBY_ENGINE="$ruby_eng"
export RUBY_ROOT="$ruby_root"
export RUBY_VERSION="$ruby_ver"
export GEM_HOME=\$(gem_calc_home)
gem_path=(\$GEM_HOME "$ruby_root/lib/$ruby_eng/gems/$ruby_ver" \$gem_path)
path=("\$RUBY_ROOT/bin" \$path)
local bin
for place in \${(Oa)gem_path}; do
  bin="\$place/bin"
	path=("\$bin" \$path)
done
unset bin
EOF
	done
	unset ruby_root ruby_ver ruby_eng key
	czruby_set_default "$RUBIES_DEFAULT"
}


# Sets the default Ruby environment to use when no specific version is specified.
czruby_set_default(){
	local choice="${1:-system}"
	[[ -z $choice ]] && return 1
	if [[ ! $rubies(Ie)$choice ]]; then
		printf "That ruby is not available"
		czruby
		return 1
	fi
	local old_default="$RUBIES_DEFAULT"
	RUBIES_DEFAULT="$choice"
	[[ -h "$czruby_datadir/default" ]] && rm "$czruby_datadir/default"
	ln -s "$czruby_datadir/${RUBIES_DEFAULT}" "$czruby_datadir/default"
	# Check if current ruby was the default
	# if so, change to new choice
	# At worst, either the user has to do this themselves
	# or set it back.
	czruby "$choice"
}

# Resets the Ruby environment to either the default or a specified version.
# It adjusts the PATH and GEM_PATH variables to match the specified environment.
czruby_reset(){
	local ver=${1:-default}
	local ruby_root="${2:-$RUBY_ROOT}"
	local excludes=()
	# TODO consider replacing loop
	for place in "$gem_path"; do
    bin="$place/bin"
	  excludes=("$bin" $excludes)
	done
	if [[ $#gem_path > 0 ]]; then
		path=(${path:|excludes})
	fi
	gem_path=()
	unset excludes
	source "$czruby_datadir/$ver"
}

# A utility function that sources the configuration file for the specified Ruby environment.
# It verifies the file's readability and sources it or calls the setup if the file is not found.
czruby_source(){
	# source the file
	if [[ -r "$1" ]]; then
		source "$1"
	else
		czruby_setup
		if [[ -r "$1" ]]; then
			source "$1"
		else
			# blow up
			echo "No source file found at $1"
			exit 1
		fi
	fi
}

# Determines which Ruby environment to use based on a partial or full match.
# It reports if there are too many matches or if the specified Ruby is unknown.
czruby_use(){
	local dir ruby ruby_root ruby_ver ruby_eng
	local matches=()
	for ruby_root in $rubies; do
		if [[ "${ruby_root:t}" =~ "-" ]]; then
			ruby_eng=${${ruby_root:t}:-ruby}
			splits=(${(s[-])ruby_eng});
			ruby_eng=$splits[1]
			ruby_ver=$splits[2]
		else
			ruby_eng="ruby"
			ruby_ver="${ruby_root:t}"
		fi
		if [[ "${ruby_root:t}" == "$1" ]]; then
			matches=("$ruby_root" $matches) && break
		# TODO consider case statement here, for performance
		elif [[ $ruby_eng == "ruby" && "$1" == $ruby_ver ]]; then
			matches=("$ruby_root" $matches) && break
		elif [[ $ruby_eng == "$1"  ]]; then
			matches=("$ruby_root" $matches)
		fi
	done
	# TODO consider case statement here, for performance
	if [[ $#matches == 0 ]]; then
		printf "czruby: unknown Ruby: %s\n" $1 >&2
		return 1
	elif [[ $#matches -ge 2 ]]; then
		printf "Too many matches, be more specific\n"
		for match in $matches; do
			printf '%s %s\n' "${match:t}" "${match}";
		done
		return 1
	fi
  czruby_reset "${matches[1]:t}" "$ruby_root"
	unset dir ruby splits ruby_root ruby_ver ruby_eng oldifs matches
}

# The main function for the script which parses command-line arguments
# and dispatches control to the appropriate function or displays information.
czruby () {
	case "$1" in
		-h|--help)
			printf "usage: czruby [RUBY|VERSION|system | --set-default RUBY] [RUBYOPT...]\n"
			;;
# 		-V|--version)
# 			echo "czruby: $CZRUBY_VERSION"
# 			;;
		"") # show available rubies
			local marked ruby_root ruby_ver ruby_eng key
			local rmarker dmarker smarker
			local stopper="%{$reset_color%}"
			local default=system
			if [[ -r "$czruby_datadir/default" ]]; then
				default="$(greadlink -f \"$czruby_datadir/default\")"
				default="${default:t}"
			fi
			typeset -A lines
			print -Pn -f '%6s| %-11s| %-10s| %4s\n' -- " " engine version root
			print -Pn -f '=%.0s' -- {1..40}
			print -n '\n'
			for ruby_root in $rubies; do
				if [[ "$ruby_root" == "system" ]]; then
					ruby_eng="ruby"
					ruby_ver="2.3.7"
					ruby_root="/usr"
					key="system"
				else
					key="${ruby_root:t}"
					if [[ "${ruby_root:t}" =~ "-" ]]; then
						ruby_eng=${${ruby_root:t}:-ruby}
						splits=(${(s[-])ruby_eng});
						ruby_eng=$splits[1]
						ruby_ver=$splits[2]
					else
						ruby_eng="ruby"
						ruby_ver="${ruby_root:t}"
					fi
				fi
				[[ "$RUBY_ROOT" == "$ruby_root" ]] && rmarker="$FG[002]*$stopper " && marked="true" || rmarker="  "
				[[ $default == $key ]] && dmarker="$FG[199]*$stopper " || dmarker="  "
				[[ $key == "system" ]] && smarker="$FG[247]*$stopper " || smarker="  "

				print -Pn -f '%2b%2b%2b %-12s %-11s %s%s\n' -- $rmarker $dmarker $smarker ${ruby_eng} $ruby_ver "${ruby_root}" $stopper
				unset rmarker dmarker smarker
			done
			print -Pn -f '\n%b %b %b' "$FG[002]current$stopper" "$FG[199]default$stopper" "$FG[247]system$stopper\n"
			unset marked rmarker ruby_root ruby_eng ruby_ver
			;;
		--set-default)	shift;
										czruby_set_default $1
										;;
		system) czruby_reset system ;;
		default) czruby_reset ;;
		*) czruby_use $1 ;;
	esac
}

# Ensures a default Ruby is set if none has been previously defined.
if [[ -z "$RUBIES_DEFAULT" ]]; then
	export RUBIES_DEFAULT="system"
fi

# Perform initial setup and set the Ruby environment to the default or specified Ruby.
czruby_setup
czruby "$RUBIES_DEFAULT"