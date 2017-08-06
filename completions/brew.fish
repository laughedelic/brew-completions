# Fish shell completions for Homebrew

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
    set -q cmds[1]; or false

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
    set opts (__fish_brew_opts)

    if not count $argv
        not count $opts
    else
        if [ "$argv[1]" = "" ]
            not count $opts
            or __fish_brew_opt $argv[2..-1]
        else
            contains -- $argv[1] $opts
            and begin
                [ (count $argv) = 1 ]
                or __fish_brew_opt $argv[2..-1]
            end
        end
    end
end
