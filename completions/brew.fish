# Fish shell completions for Homebrew

##########################
## COMMAND LINE PARSING ##
##########################

function __fish_brew_args -d 'returns a list of all arguments given to brew'

    set -l tokens (commandline --tokenize --current-process --cut-at-cursor)
    set -e tokens[1] # remove 'brew'
    for t in $tokens
        echo $t
    end
end

function __fish_brew_opts -d 'Only arguments starting with a dash (options)'
    string match --all -- '-*' (__fish_brew_args)
end

# This can be used either to get the first argument or to match it against a given list of commmands
#
# Usage examples (for `completion -n '...'`):
# * `__fish_brew_command` returns the command (first arg of brew) or exits with 1
# * `not __fish_brew_command` returns true when brew doesn't have a command yet
# * `__fish_brew_command list ls` returns true when brew command is _either_ `list` _or_ `ls`
#
function __fish_brew_command -d 'Helps matching the first argument of brew'
    set cmds (__fish_brew_args)
    set -q cmds[1]; or return 1

    if count $argv
        contains -- $cmds[1] $argv
    else
        echo $cmds[1]
    end
end

# This can be used to match any given options agains the given list of arguments:
# * to add condition on interdependent options
# * to ddd condition on mutually exclusive options
#
# Usage examples (for `completion -n '...'`):
# * `__fish_brew_opt -s --long` returns true if _either_ `-s` _or_ `--long` is present
# * `not __fish_brew_opt --foo --bar` will work only if _neither_ `--foo` _nor_ `--bar` are present
#
function __fish_brew_opt -d 'Helps matching brew options against the given list'

    not count $argv
    or contains -- $argv[1] (__fish_brew_opts)
    or begin
        set -q argv[2]
        and __fish_brew_opt $argv[2..-1]
    end
end


######################
## SUGGESTION LISTS ##
######################

# These functions return lists of completed arguments
function __fish_brew_formulae_all
    brew search
end

function __fish_brew_formulae_installed
    brew list
end

function __fish_brew_formulae_pinned
    brew list --pinned
end

function __fish_brew_formulae_multiple_versions -d 'List of installed formulae with their multiple versions'
    brew list --versions --multiple \
        # replace first space with tab to make the following a description in the completions list:
        | string replace -r '\s' '\t' \
        # a more visible versions separator:
        | string replace --all ' ' ', '
end

function __fish_brew_formula_versions -a formula -d 'List of versions for a given formula'
    brew list --versions $formula \
        # cut off the first word in the output which is the formula name
        | string replace -r '\S+\s+' '' \
        # make it a list
        | string split ' '
end

function __fish_brew_formulae_outdated -d 'Returns a list of outdated formulae with the information about potential upgrade'
    brew outdated --verbose \
        # replace first space with tab to make the following a description in the completions list:
        | string replace -r '\s' '\t'
end

function __fish_brew_commands_list -d "Lists all commands names, including aliases"
    brew commands --quiet --include-aliases
end


##########################
## COMPLETION SHORTCUTS ##
##########################

function __complete_brew_cmd -a cmd -d "A shortcut for defining brew commands completions"
    set -e argv[1]
    complete -f -c brew -n 'not __fish_brew_command' -a $cmd -d $argv
end

function __complete_brew_arg -a cond -d "A shortcut for defining arguments completion for brew commands"
    set -e argv[1]
    # NOTE: $cond can be just a name of a command (or several) or additionally any other condition
    complete -f -c brew -n "__fish_brew_command $cond" $argv
end

# testing outdated formulae completion
complete -f -c brew -n '__fish_brew_command upgrade' \
    -a '(__fish_brew_formulae_outdated)'

# testing switch completion: first arg is a formula with multiple version
complete -f -r -c brew -n '__fish_brew_command switch; and [ (count (__fish_brew_args)) = 1 ]' \
    -a '(__fish_brew_formulae_multiple_versions)'

# second arg is a list of versions for the formula (which is the previous arg)
complete -f -r -c brew -n '__fish_brew_command switch; and [ (count (__fish_brew_args)) = 2 ]' \
    -a '(__fish_brew_formula_versions (__fish_brew_args)[-1])'


##############
## COMMANDS ##
##############


__complete_brew_cmd 'cat' 'Display the source to formula'
__complete_brew_arg 'cat' -a '(__fish_brew_formulae_all)'


__complete_brew_cmd 'cleanup' 'Remove old installed versions'
__complete_brew_arg 'cleanup' -a '(__fish_brew_installed_formulas)'
__complete_brew_arg 'cleanup'      -l prune   -d 'Remove all cache files older than given number of days' -a '(seq 1 5)'
__complete_brew_arg 'cleanup' -s n -l dry-run -d 'Show what files would be removed'
__complete_brew_arg 'cleanup' -s s            -d 'Scrub the cache, removing downloads for even the latest versions of formulae'


__complete_brew_cmd 'command' 'Display the path to command file'
__complete_brew_arg 'command' -a '__fish_brew_commands_list'


__complete_brew_cmd 'commands' 'List built-in and external commands'
__complete_brew_arg 'commands' -l quiet           -d 'List only the names of commands without the header'
__complete_brew_arg 'commands; and __fish_brew_opt --quiet' \
                                    -l include-aliases -d 'The aliases of internal commands will be included'


__complete_brew_cmd 'config' 'Show Homebrew and system configuration for debugging'


__complete_brew_cmd 'deps' 'Show dependencies for given formulae'
# accepts formulae argument only without --all or --installed options:
__complete_brew_arg 'deps; and not __fish_brew_opt --all --installed' -a '(__fish_brew_formulae_all)'
# options that work only without --tree:
__complete_brew_arg 'deps; and not __fish_brew_opt --tree' -s n         -d 'Show in topological order'
__complete_brew_arg 'deps; and not __fish_brew_opt --tree' -l 1         -d 'Show only 1 level down'
__complete_brew_arg 'deps; and not __fish_brew_opt --tree' -l union     -d 'Show the union of dependencies for formulae, instead of the intersection'
__complete_brew_arg 'deps; and not __fish_brew_opt --tree' -l full-name -d 'List dependencies by their full name'
# --all and --installed are mutually exclusive:
__complete_brew_arg 'deps; and not __fish_brew_opt --installed --tree' -l all       -d 'Show dependencies for all formulae'
__complete_brew_arg 'deps; and not __fish_brew_opt --all'              -l installed -d 'Show dependencies for installed formulae'
# --tree works without options or with --installed
__complete_brew_arg 'deps;
    and begin
        not __fish_brew_opts;
        or __fish_brew_opt --installed;
    end' -l tree -d 'Show dependencies as tree'
# filters can be passed with any other options
__complete_brew_arg 'deps' -l include-build    -d 'Include the :build type dependencies'
__complete_brew_arg 'deps' -l include-optional -d 'Include the :optional type dependencies'
__complete_brew_arg 'deps' -l skip-recommended -d 'Skip :recommended  type  dependencies'


__complete_brew_cmd 'desc' 'Show formulae description or search by name and/or description'
__complete_brew_arg 'desc; and [ (count (__fish_brew_args)) = 1 ]' -a '(__fish_brew_formulae_all)'
# FIXME: -n behaves differently from everything else
__complete_brew_arg 'desc; and [ (count (__fish_brew_args)) = 1 ]' -r -s n -l name        -d 'Search only names'
__complete_brew_arg 'desc; and [ (count (__fish_brew_args)) = 1 ]' -r -s d -l description -d 'Search only descriptions'
__complete_brew_arg 'desc; and [ (count (__fish_brew_args)) = 1 ]' -r -s s -l search      -d 'Search names and descriptions'


__complete_brew_cmd 'diy' 'Determine installation prefix for non-brew software'
__complete_brew_arg 'diy configure' -r -l 'name=name'       -d 'Set name of package'
__complete_brew_arg 'diy configure' -r -l 'version=version' -d 'Set version of package'


__complete_brew_cmd 'doctor' 'Check your system for potential problems'


__complete_brew_cmd 'fetch' 'Download source packages for given formulae'
__complete_brew_arg 'fetch' -a '(__fish_brew_formulae_all)'
__complete_brew_arg 'fetch' -s f -l force             -d 'Remove a previously cached version and re-fetch'
__complete_brew_arg 'fetch' -l deps              -d 'Also download dependencies'
__complete_brew_arg 'fetch' -l build-from-source -d 'Fetch source package instead of bottle'
__complete_brew_arg 'fetch' -s v -l verbose                -d 'Do a verbose VCS checkout'
__complete_brew_arg 'fetch' -l retry              -d 'Retry if a download fails or re-download if the checksum has changed'
# --HEAD and --devel are mutually exclusive:
__complete_brew_arg 'fetch; and not __fish_brew_opt --HEAD'  -l devel             -d 'Download the development version from a VCS'
__complete_brew_arg 'fetch; and not __fish_brew_opt --devel' -l HEAD              -d 'Download the HEAD version from a VCS'
# --build-from-source and --force-bottle are mutually exclusive:
__complete_brew_arg 'fetch; and not __fish_brew_opt --force-bottle'    -s s -l build-from-source -d 'Download the source rather than a bottle'
__complete_brew_arg 'fetch; and not __fish_brew_opt --build-from-source -s' -l force-bottle      -d 'Download a bottle if it exists'


__complete_brew_cmd 'gist-logs' 'Upload logs for a failed build of formula to a new Gist'
__complete_brew_arg 'gist-logs' -a '(__fish_brew_formulae_all)'
__complete_brew_arg 'gist-logs' -a '(__fish_brew_formulae_all)'
__complete_brew_arg 'gist-logs' -s n -l new-issue -d 'Also create a new issue in the appropriate GitHub repository'


__complete_brew_cmd 'help' 'Display help for given command'
__complete_brew_arg 'help' -a '(__fish_brew_commands_list)'


__complete_brew_cmd 'home' 'Open Homebrew/formula\'s homepage'
__complete_brew_arg 'home' -a '(__fish_brew_formulae_all)'


__complete_brew_cmd 'info' 'Display information about formula'
# suggest formulae names only without --all/--installed options;
__complete_brew_arg 'info abv; and not __fish_brew_opt --all --installed' -a '(__fish_brew_formulae_all)'
# --github or --json are applicable only without other options
__complete_brew_arg 'info abv; and not __fish_brew_opts' -l github  -d 'Open the GitHub History page for formula'
__complete_brew_arg 'info abv; and not __fish_brew_opts' -l json=v1 -d 'Print a JSON representation of formulae'
# --all and --installed require --json option and are mutually exclusive:
__complete_brew_arg 'info abv;
    and begin
        __fish_brew_opt --json=v1;
        and not __fish_brew_opt --installed --all
    end' -l all       -d 'Display JSON info for all formulae'
__complete_brew_arg 'info abv;
    and begin
        __fish_brew_opt --json=v1;
        and not __fish_brew_opt --installed --all
    end' -l installed -d 'Display JSON info for installed formulae'
