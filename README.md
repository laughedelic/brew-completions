# 🍺 [Homebrew] 🐟 [Fish shell] completions

[![](https://img.shields.io/github/release/laughedelic/brew-completions.svg)](https://github.com/laughedelic/brew-completions/releases/latest)
[![](https://img.shields.io/badge/license-LGPLv3-blue.svg)](https://www.tldrlegal.com/l/lgpl-3.0)
[![](https://img.shields.io/badge/chat-gitter-dd1054.svg)][gitter]

[Fish shell] completions for [Homebrew].

## STATUS this plugin has been [merged upstream](https://github.com/Homebrew/brew/pull/6217), so the repository is archived.

---

Fish includes some basic completions for brew, but a lot of commands and options are missing/outdated. So this work is aiming to fill the gap and provide a **comprehensive Homebrew completions plugin**. It supports

* all 75 core brew commands (85 with aliases) and all their options
* official external commands with their subcommands and options:
  - [`bundle`](https://github.com/Homebrew/homebrew-bundle): Bundler for non-Ruby dependencies from Homebrew
  - [`cask`](https://github.com/caskroom/homebrew-cask): Install macOS applications distributed as binaries
  - [`services`](https://github.com/Homebrew/homebrew-services): Integrates Homebrew formulae with macOS's `launchctl` manager
* besides basic options completion, it also takes into account when some options are _mutually exclusive_ or _depend on other options_

It is mostly based on the Homebrew documentation: manpage + `brew help`, but it also includes several "undocumented" commands, supported by Homebrew.


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
