# shellcheck shell=bash

# shellcheck source=/dev/null
if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then . "$HOME/.nix-profile/etc/profile.d/nix.sh"; fi # added by Nix installer

# don't continue unless interactive
if [[ -z $PS1 ]]; then return; fi

if [[ -z "$__DOT_BASHRC_SOURCED" ]]; then
  __DOT_BASHRC_SOURCED=1
else
  return
fi

# show PS1 is ignored (set in post-cmd hook)
unset PS1

unset MAILCHECK # don't nag me about mail

export VISUAL="pico"

# history mods
# TODO: do any of these belong in hag? Tests?
export HISTTIMEFORMAT="%h %d %H:%M:%S>"
export HISTCONTROL="ignoredups:ignorespace"
export HISTIGNORE="ping*:vagrant @(up|ssh|halt|suspend|destroy|provision|--version):npm start:l@(l|s):ls -@(l|la):find .:rsync*:hugo@( -w):python?(2|3):git @(status|log|diff|remote?( -v)|branch?( -v?(a))):man*:ifconfig:history*"

# shellcheck disable=SC1091
source hag.bash
# shellcheck disable=SC1091
source lilgit.bash

# === prompt ===
# FOR SANITY:
# - SINGLE QUOTES FOR PROMPT SEGMENTS WITH EITHER:
#   - NO VARIABLES
#   - PROMPT-TIME VARIABLES
# - DOUBLE QUOTES FOR DEF-TIME (~ cached) VARIABLES
unset PROMPT_DIRTRIM
PROMPT_COMMAND="" # throw out macOS timewasting

# TODO: someday I'd like to compile this in from a shared util lib
#       (without including the whole util lib)
# arg: timestamp as produced by ${EPOCHREALTIME/.}
# (microsecond resolution)
function __describe_duration()
{
  local d="$1"
  # new version, save time, direct math:
  if   ((d >  3600000000)); then                 # >1   hour
    local m=$(((((d/1000) / 1000) / 60) % 60))
    local h=$((((d/1000) / 1000) / 3600))
    printf "%dh%dm" $h $m
  elif ((d >  60000000)); then                   # >1   minute
    local s=$((((d/1000) / 1000) % 60))
    local m=$(((((d/1000) / 1000) / 60) % 60))
    printf "%dm%ds" $m $s
  elif ((d >= 10000000)); then                   # >=10 seconds
    local ms=$(((d/1000) % 1000))
    local s=$((((d/1000) / 1000) % 60))
    printf "%d.%ds" $s $((ms / 100))
  elif ((d >=  1000000)); then                   # > 1  second
    local ms=$(((d/1000) % 1000))
    local s=$((((d/1000) / 1000) % 60))
    printf "%d.%ds" $s $((ms / 10))
  elif ((d >=  100000)); then                    # > 100  ms
    local ms=$(((d/1000) % 1000))
    printf "%dms" $ms
  elif ((d >=  20000)); then                     # > 20  ms
    local ms=$(((d/1000)))
    # printf "%dms" $ms
    printf "%d.%dms" $ms $((d % 10))
  elif ((d >=  10000)); then                     # > 10  ms
    local ms=$(((d/1000)))
    # printf "%dms" $ms
    printf "%d.%dms" $ms $((d % 100))
  elif ((d >=  1000)); then                      # > 1  ms
    local ms=$(((d/1000)))
    # printf "%dms" $ms
    printf "%d.%dms" $ms $((d % 1000))
  else                                           # < 1  ms (1000 µs)
    printf "%dµs" "$d"
  fi
}

function __start()
{
  # shellcheck disable=SC2154
  printf '\033[1m%s --> \033[0m\n' "${swain[start_time]}"
}

function __end()
{
  printf '%s (%s)\n' "${swain[end_time]}" "$(__describe_duration "${swain[duration]}")"
}

# function to wrap this up and explain it, but it's computed once on load
function __build_line3()
{
  local __in=''
  # we'll pull #N of these based on SHLVL
  local local_pointy='>>>>>>>>>>'
  local remote_pointy='<<<<<<<<<<'

  local __username='\[\033[35m\]\u\[\033[0;1m\]'
  local __hostname='\[\033[1;34m\]\h\[\033[0;1m\]'
  if [[ -n "$SSH_CONNECTION" ]]; then
    local pointy_color='\[\033[0;31m\]%s\[\033[0m\]'
    local arrows="${remote_pointy:0:$SHLVL}"
  else
    local pointy_color='\[\033[0;34m\]%s\[\033[0m\]'
    local arrows="${local_pointy:0:$SHLVL}"
  fi

  # shellcheck disable=SC2059
  printf -v __arrows "$pointy_color" "$arrows"

  if [[ -n "$IN_NIX_SHELL" ]]; then
    __in=' in \[\033[32m\]nix-shell\[\033[0;1m\]'
  fi

  __line3="\n\[\033[1m\]╚═\[\033[32m\]$__arrows $__username$__in on $__hostname \$ "
}

# TODO: hooks could prolly make this better
function __build_prompt()
{
  # shellcheck disable=SC2155
  IFS= local duration="$(__end)"
  if [[ -n "$duration" ]]; then
    __line1="\[\033[1m\]$duration\[\033[0m\]\n\n"
    export PS1="$__line1$__line2$__line3\[\033[0m\]"
  else
    __line1=''
    export PS1="$__line2$__line3\[\033[0m\]"
  fi
}

__line1="" # rebuilt on each prompt
# shellcheck disable=SC2154
__line2="\[\033[1m\]╓─[ \$HAG_PURPOSE ]$__lilgit \[\033[1;33m\]\w\[\033[0m\]"
__build_line3

# TODO: should/could this be a swain or hag API?
# __swain_prompt __start __build_prompt
event on swain:before_first_prompt __build_prompt
event on swain:before_command __start
event on swain:after_command __build_prompt
event on swain:before_exit __go_off_now_lilgit
