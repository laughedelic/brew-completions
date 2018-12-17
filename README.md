# 🍺 [Homebrew] 🐟 [Fish shell] completions

[![](https://img.shields.io/github/release/laughedelic/brew-completions.svg)](https://github.com/laughedelic/brew-completions/releases/latest)
[![](https://img.shields.io/badge/license-LGPLv3-blue.svg)](https://www.tldrlegal.com/l/lgpl-3.0)
[![](https://img.shields.io/badge/chat-gitter-dd1054.svg)][gitter]

[Fish shell] completions for [Homebrew].

Fish includes some basic completions for brew, but a lot of commands and options are missing/outdated. So this work is aiming to fill the gap and provide a **comprehensive Homebrew completions plugin**. It supports

* all 75 core brew commands (85 with aliases) and all their options
* official external commands with their subcommands and options:
  - [`bundle`](https://github.com/Homebrew/homebrew-bundle): Bundler for non-Ruby dependencies from Homebrew
  - [`cask`](https://github.com/caskroom/homebrew-cask): Install macOS applications distributed as binaries
  - [`services`](https://github.com/Homebrew/homebrew-services): Integrates Homebrew formulae with macOS's `launchctl` manager
* besides basic options completion, it also takes into account when some options are _mutually exclusive_ or _depend on other options_

It is mostly based on the Homebrew documentation: manpage + `brew help`, but it also includes several "undocumented" commands, supported by Homebrew.


##### A note about beta

This plugin is in beta, so you're welcome to try it out and report any issues you found. The code also includes some `FIXME` and `TODO` notes marking potential improvements/issues. If you have any suggestions or ideas, you're welcome to [open issues](https://github.com/laughedelic/brew-completions/issues/new) or join the [gitter chat][gitter].

Once it's considered stable, it may get either included with Homebrew or replace completions shipped with Fish.

For now you can install it with either Fish plugin manager (you can also install it manually by copying the `completions/brew.fish` file, but it's not recommended because you won't get updates automatically).


## Install

* Using [fisher](https://github.com/jorgebucaran/fisher):
  ```fish
  fisher add laughedelic/brew-completions
  ```

* Using [oh-my-fish](https://github.com/oh-my-fish/oh-my-fish):
  ```fish
  omf install https://github.com/laughedelic/brew-completions
  ```

* Using [fin](https://github.com/fisherman/fin):
  ```fish
  echo laughedelic/brew-completions >> ~/.config/fish/fishfile; and fin
  ```


[Fish shell]: https://github.com/fish-shell/fish-shell
[Homebrew]: https://brew.sh/
[gitter]: https://gitter.im/laughedelic/brew-completions
