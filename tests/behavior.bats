bats_load_library bats-require
load helpers

# TODO: clearly describe why some of these need unbuffer? or maybe just abstract it out and auto-apply it in all cases for consistency if it doesn't cause trouble?

@test "loads and presents expected prompt" {
  require <({
    status 0
    # terminal title emitted by setting a purpose
    line -2 equals $'\E[1m\342\225\223\342\224\200[ porpoise ] \E[1;33m~\E[0m\r\r'
    line -1 equals $'\E[1m\342\225\232\342\225\220\E[32m\E[0;34m>>>>>>\E[0m \E[35mabathur\E[0;1m on \E[1;34mde300867\E[0;1m $ \E[0m'
  })
} <<CASES
unbuffer ./prompt.bash
CASES
