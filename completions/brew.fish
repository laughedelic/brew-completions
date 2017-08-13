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
    brew list --pinned --versions \
        # replace first space with tab to make the following a description in the completions list:
        | string replace -r '\s' '\t'
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

function __fish_brew_formula_options -a formula -d 'List installation options for a given formula'
    function list_pairs
        set -q argv[2]; or return 0
        echo $argv[1]\t$argv[2]
        set -e argv[1..2]
        list_pairs $argv
    end

    # brew options lists options name and its description on different lines
    list_pairs (brew options $formula | string trim)
end

function __fish_brew_formulae_outdated -d 'List of outdated formulae with the information about potential upgrade'
    brew outdated --verbose \
        # replace first space with tab to make the following a description in the completions list:
        | string replace -r '\s' '\t'
end

function __fish_brew_taps_installed -d 'List all available taps'
    brew tap
end

function __fish_brew_taps_pinned -d 'List only pinned taps'
    brew tap --list-pinned
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


##############
## COMMANDS ##
##############


__complete_brew_cmd 'cat' 'Display the source to formula'
__complete_brew_arg 'cat' -a '(__fish_brew_formulae_all)'


__complete_brew_cmd 'cleanup' 'Remove old installed versions'
__complete_brew_arg 'cleanup' -a '(__fish_brew_formulae_installed)'
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


__complete_brew_cmd 'install' 'Install formula'
__complete_brew_arg 'install' -a '(__fish_brew_formulae_all)'
# NOTE: upgrade command accepts same options as install
__complete_brew_arg 'install upgrade' -s d -l debug -d 'If install fails, open shell in temp directory'
# --env takes single obligatory argument:
__complete_brew_arg 'install upgrade; and not __fish_brew_opt --env' -l env -d 'Specify build environment' -r -a '
    std\t"Use standard build environment"
    super\t"Use superenv"
'
# --ignore-dependencies and --only-dependencies are mutually exclusive:
__complete_brew_arg 'install upgrade;
    and not __fish_brew_opt --only-dependencies --ignore-dependencies
    ' -l ignore-dependencies -d 'Skip installing any dependencies of any kind'
__complete_brew_arg 'install upgrade;
    and not __fish_brew_opt --only-dependencies --ignore-dependencies
    ' -l only-dependencies   -d 'Install dependencies but not the formula itself'
__complete_brew_arg 'install upgrade' -l cc -d 'Attempt to compile using the specified compiler' \
    -a 'clang gcc-4.0 gcc-4.2 gcc-4.3 gcc-4.4 gcc-4.5 gcc-4.6 gcc-4.7 gcc-4.8 gcc-4.9 llvm-gcc'
# --build-from-source and --force-bottle are mutually exclusive:
__complete_brew_arg 'install upgrade; and not __fish_brew_opt --force-bottle'    -s s -l build-from-source -d 'Compile the formula from source'
# FIXME: -s misbehaves allowing --force-bottle
__complete_brew_arg 'install upgrade; and not __fish_brew_opt -s --build-from-source' -l force-bottle      -d 'Install from a bottle if it exists'
# --HEAD and --devel are mutually exclusive:
__complete_brew_arg 'install upgrade; and not __fish_brew_opt --HEAD'  -l devel -d 'Install the development version'
__complete_brew_arg 'install upgrade; and not __fish_brew_opt --devel' -l HEAD  -d 'Install the HEAD version'
__complete_brew_arg 'install upgrade'      -l keep-tmp     -d 'Keep temp files created during installation'
__complete_brew_arg 'install upgrade'      -l build-bottle -d 'Prepare the formula for eventual bottling during installation'
__complete_brew_arg 'install upgrade' -s i -l interactive  -d 'Download and patch formula, then open a shell'
__complete_brew_arg 'install upgrade; and __fish_brew_opt -i --interactive' -s g -l git -d 'Create a Git repository for working on patches'
# fomrula installtion options are listed after the formula name:
__complete_brew_arg 'install;
    and [ (count (__fish_brew_args)) -ge 2 ];
    and not string match --quiet -- "-*" (__fish_brew_args)[-1]
    ' -a '(__fish_brew_formula_options (__fish_brew_args)[-1])'


__complete_brew_cmd 'irb' 'Enter the interactive Homebrew Ruby shell'
__complete_brew_arg 'irb' -l examples -d 'Show several examples'


__complete_brew_cmd 'leaves' 'Installed formulae that are not dependencies of another installed formula'


__complete_brew_cmd 'link' 'Symlink installed formula files'
__complete_brew_arg 'link ln' -a '(__fish_brew_formulae_installed)'
__complete_brew_arg 'link ln'      -l overwrite -d 'Overwrite existing files'
__complete_brew_arg 'link ln' -s n -l dry-run   -d 'Show what files would be linked or overwritten'
__complete_brew_arg 'link ln' -s f -l force     -d 'Allow keg-only formulae to be linked'


__complete_brew_cmd 'linkapps' 'Symlink .app bundles into /Applications (deprecated)'
__complete_brew_arg 'linkapps' -a '(__fish_brew_formulae_installed)'
__complete_brew_arg 'linkapps' -l local -d 'Link into ~/Applications instead'


__complete_brew_cmd 'list' 'List installed formulae'
__complete_brew_arg 'list ls' -a '(__fish_brew_formulae_installed)'
# --full-name or --unbrewed exclude any other arguments or options
__complete_brew_arg 'list ls; and [ (count (__fish_brew_args)) = 1 ]' -l full-name -d 'Print formulae with fully-qualified names'
__complete_brew_arg 'list ls; and [ (count (__fish_brew_args)) = 1 ]' -l unbrewed -d 'List all files in the Homebrew prefix not installed by brew'
# --versions and --pinned work only with each other or alone
__complete_brew_arg 'list ls;
    and begin
        not __fish_brew_opts;
        or      __fish_brew_opt --versions
        and not __fish_brew_opt --pinned
    end' -l pinned   -d 'Show the versions of pinned formulae'
__complete_brew_arg 'list ls;
    and begin
        not __fish_brew_opts;
        or      __fish_brew_opt --pinned
        and not __fish_brew_opt --versions
    end' -l versions -d 'Show the version number'
# --multiple is an additional option for --versions
__complete_brew_arg 'list ls;
    and     __fish_brew_opt --versions
    and not __fish_brew_opt --multiple
    ' -l multiple -d 'Only show formulae with multiple versions'


__complete_brew_cmd 'log' 'Show git log for formula'
__complete_brew_arg 'log' -a '(__fish_brew_formulae_all)'


__complete_brew_cmd 'migrate' 'Migrate renamed packages to new name'
# NOTE: should this work only with installed formulae?
__complete_brew_arg 'migrate' -a '(__fish_brew_formulae_all)'
__complete_brew_arg 'migrate' -s f -l force -d 'Treat installed and passed formulae like if they are from same taps and migrate them anyway'


__complete_brew_cmd 'missing' 'Check given formula (or all) for missing dependencies'
__complete_brew_arg 'missing' -a '(__fish_brew_formulae_installed)'
__complete_brew_arg 'missing' -l hide -d 'Act as if it\'s not installed' -r -a '(__fish_brew_formulae_installed)'


__complete_brew_cmd 'options' 'Display install options for formula'
__complete_brew_arg 'options; and not __fish_brew_opt --installed --all' -a '(__fish_brew_formulae_all)'
__complete_brew_arg 'options; and not __fish_brew_opt --installed --all' -l all       -d 'Show options for all formulae'
__complete_brew_arg 'options; and not __fish_brew_opt --installed --all' -l installed -d 'Show options for all installed formulae'
__complete_brew_arg 'options' -l compact -d 'Show options as a space-delimited list'


__complete_brew_cmd 'outdated' 'Show formula that have updated version available'
__complete_brew_arg 'outdated; and not __fish_brew_opt --quiet -v --verbose --json=v1'      -l quiet   -d 'Display only names'
__complete_brew_arg 'outdated; and not __fish_brew_opt --quiet -v --verbose --json=v1' -s v -l verbose -d 'Display detailed version information'
__complete_brew_arg 'outdated; and not __fish_brew_opt --quiet -v --verbose --json=v1'      -l json=v1 -d 'Format output in JSON format'
# NOTE: check if this option requires a formula argument:
__complete_brew_arg 'outdated' -l fetch-HEAD -d 'Fetch the upstream repository to detect if the HEAD installation is outdated'


# TODO: should suggest only unpinned formulae and show their current versions in the description
__complete_brew_cmd 'pin' 'Pin the specified formulae to their current versions'
__complete_brew_arg 'pin' -a '(__fish_brew_formulae_installed)'


__complete_brew_cmd 'postinstall' 'Rerun the post-install steps for formula'
__complete_brew_arg 'postinstall' -a '(__fish_brew_formulae_installed)'


__complete_brew_cmd 'prune' 'Remove dead symlinks'
__complete_brew_arg 'prune' -s n -l dry-run -d 'Show what files would be removed'


__complete_brew_cmd 'reinstall' 'Uninstall and then install again'
__complete_brew_arg 'reinstall' -a '(__fish_brew_formulae_installed)'


__complete_brew_cmd 'search' 'Display all locally available formulae or search by name/description'
__complete_brew_arg 'search -S; and not __fish_brew_opts' -l desc -d 'Search also in descriptions'
for repo in debian fedora fink macports opensuse ubuntu
    __complete_brew_arg "search -S; and not __fish_brew_opts" -l $repo -d 'Search only in this repository'
end


__complete_brew_cmd 'sh' 'Start a Homebrew build environment shell'
__complete_brew_arg 'sh' -l env=std -d 'Use standard PATH instead of superenv\'s'


__complete_brew_cmd 'style' 'Check Homebrew style guidelines for formulae or files'
# NOTE: is it OK to use (ls) for suggestions?
__complete_brew_arg 'style' -a '(ls)'                             -d 'File'
__complete_brew_arg 'style' -a '(__fish_brew_taps_installed)'               -d 'Tap'
__complete_brew_arg 'style' -a '(__fish_brew_formulae_installed)' -d 'Formula'
__complete_brew_arg 'style' -l fix -d 'Use RuboCop\'s --auto-correct feature'
__complete_brew_arg 'style' -l display-cop-names -d 'Output RuboCop cop name for each violation'
# --only-cops and --except-cops are mutually exclusive:
__complete_brew_arg 'style; and not __fish_brew_opt --only-cops --except-cops' -l only-cops   -d 'Use only given Rubocop cops'
__complete_brew_arg 'style; and not __fish_brew_opt --only-cops --except-cops' -l except-cops -d 'Skip given Rubocop cops'


__complete_brew_cmd 'switch' 'Switch formula to another installed version'
# first argument is a formula with multiple versions:
__complete_brew_arg 'switch; and [ (count (__fish_brew_args)) = 1 ]' -a '(__fish_brew_formulae_multiple_versions)'
# second argument is a list of versions for the previous argument:
__complete_brew_arg 'switch; and [ (count (__fish_brew_args)) = 2 ]' -a '(__fish_brew_formula_versions (__fish_brew_args)[-1])'


__complete_brew_cmd 'tap' 'List installed taps or install a new tap'
__complete_brew_arg 'tap; and not __fish_brew_opts' -l full          -d 'Clone full repository instead of a shallow copy'
__complete_brew_arg 'tap; and not __fish_brew_opts' -l repair        -d 'Migrate tapped formulae from symlink-based to directory-based structure'
__complete_brew_arg 'tap; and not __fish_brew_opts' -l list-official -d 'List all official taps'
__complete_brew_arg 'tap; and not __fish_brew_opts' -l list-pinned   -d 'List all pinned taps'


__complete_brew_cmd 'tap-info' 'Display a brief summary of all installed taps'
__complete_brew_arg 'tap-info; and not __fish_brew_opt --installed' -a '(__fish_brew_taps_installed)'
__complete_brew_arg 'tap-info; and not __fish_brew_opt --installed' -l installed -d 'Display information on all installed taps'
__complete_brew_arg 'tap-info; and not __fish_brew_opt --json=v1'   -l json=v1   -d 'Format output in JSON format'


__complete_brew_cmd 'tap-pin' 'Prioritize tap\'s formulae over core'
__complete_brew_arg 'tap-pin' -a '(__fish_brew_taps_installed)'


__complete_brew_cmd 'tap-unpin' 'Don\'t prioritize tap\'s formulae over core anymore'
__complete_brew_arg 'tap-unpin' -a '(__fish_brew_taps_pinned)'


__complete_brew_cmd 'uninstall' 'Uninstall formula'
__complete_brew_arg 'uninstall remove rm' -a '(__fish_brew_formulae_installed)'
__complete_brew_arg 'uninstall remove rm' -s f -l force               -d 'Delete all installed versions'
__complete_brew_arg 'uninstall remove rm'      -l ignore-dependencies -d 'Won\'t fail, even if dependent formulae would still be installed'


__complete_brew_cmd 'unlink' 'Unlink formula'
__complete_brew_arg 'unlink' -a '(__fish_brew_formulae_installed)'
__complete_brew_arg 'unlink' -s n -l dry-run -d 'Show what files would be unlinked'


__complete_brew_cmd 'unlinkapps' 'Remove symlinks created by brew linkapps (deprecated)'
__complete_brew_arg 'unlinkapps' -a '(__fish_brew_formulae_installed)'
__complete_brew_arg 'unlinkapps'      -l local   -d 'Remove symlinks from ~/Applications'
__complete_brew_arg 'unlinkapps' -s n -l dry-run -d 'Show what symlinks would be removed'


__complete_brew_cmd 'unpack' 'Unpack formulae source files into current/given directory'
__complete_brew_arg 'unpack' -a '(__fish_brew_formulae_all)'
__complete_brew_arg 'unpack'      -l patch   -d 'Apply patches to the unpacked source'
__complete_brew_arg 'unpack' -s g -l git     -d 'Initialize Git repository in the unpacked source'
__complete_brew_arg 'unpack'      -l destdir -d 'Unpack into the given directory' -r -a '(__fish_complete_directories "" "")'


__complete_brew_cmd 'unpin' 'Unpin formulae, allowing them to be upgraded'
__complete_brew_arg 'unpin' -a '(__fish_brew_formulae_pinned)'


__complete_brew_cmd 'untap' 'Remove a tapped repository'
__complete_brew_arg 'untap' -a '(__fish_brew_taps_installed)'


__complete_brew_cmd 'update' 'Fetch newest version of Homebrew and formulae'
__complete_brew_arg 'update'      -l merge -d 'Use git merge (rather than git rebase)'
__complete_brew_arg 'update' -s f -l force -d 'Always do a slower, full update check'


__complete_brew_cmd 'upgrade' 'Upgrade outdated brews'
__complete_brew_arg 'upgrade' -a '(__fish_brew_formulae_outdated)'
__complete_brew_arg 'upgrade' -l cleanup -d 'Remove previously installed versions'
__complete_brew_arg 'upgrade' -l fetch-HEAD -d 'Fetch the upstream repository to detect if the HEAD installation is outdated'
__complete_brew_arg 'upgrade' -a '(complete -C"brew install -")'
