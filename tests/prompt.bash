expect <<EOF
	spawn -noecho bash --noprofile --rcfile "$(type -p bashrc)"
	stty -echo
	expect ":( hag doesn't have a purpose; please set one:" {
		send -- "porpoise\r"
		expect "porpoise\r\n" {
			expect "\u001b]1;porpoise\u0007\u001b]2;\u0007" {
				expect "Should hag track the history for purpose 'porpoise'" {
					send -- "y\r"
					expect "y\r\n"
				}
				expect "hag is tracking history" {
					expect "$HOSTNAME" {
						send -- "exit\r"
					}
				}
			}
		}
	}
EOF
