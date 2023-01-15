# bashrc.nix
This nix flake shows how I use a few of my projects in my bash shell init and prompt.

## Projects incorporated
- [shell-hag](https://github.com/abathur/shell-hag): project-based shell history aggregator
- [shellswain](https://github.com/abathur/shellswain): enables simple, neighborly, event-driven shell profile modules. It is pulled in via shell-hag, but I also use it directly.
- [lilgit](https://github.com/abathur/lilgit): a small, minimalistic git status prompt plugin

## Prompt

My prompts look like:

```
╓─[ bashrc.nix ] main ~/work/bashrc.nix
╚═> abathur on 7306738e $ ls
Sat Jan 14 2023 15:54:25 -->
LICENSE  README.md  bashrc  bashrc.nix  default.nix  flake.lock  flake.nix   tests
Sat Jan 14 2023 15:54:25 (16.77ms)
```
