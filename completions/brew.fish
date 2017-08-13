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


__complete_brew_cmd 'diy' 'Determine installation prefix for non-brew software'
__complete_brew_arg 'diy configure' -r -l 'name=name'       -d 'Set name of package'
__complete_brew_arg 'diy configure' -r -l 'version=version' -d 'Set version of package'


__complete_brew_cmd 'doctor' 'Check your system for potential problems'


__complete_brew_cmd 'gist-logs' 'Upload logs for a failed build of formula to a new Gist'
__complete_brew_arg 'gist-logs' -a '(__fish_brew_formulae_all)'
__complete_brew_arg 'gist-logs' -a '(__fish_brew_formulae_all)'
__complete_brew_arg 'gist-logs' -s n -l new-issue -d 'Also create a new issue in the appropriate GitHub repository'


__complete_brew_cmd 'help' 'Display help for given command'
__complete_brew_arg 'help' -a '(__fish_brew_commands_list)'


__complete_brew_cmd 'home' 'Open Homebrew/formula\'s homepage'
__complete_brew_arg 'home' -a '(__fish_brew_formulae_all)'
