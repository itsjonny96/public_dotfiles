# Custom GOTD (persists across sessions, not overwritten by system updates)
# Suppresses system /etc/motd via ~/.hushlogin, prints custom greeting instead
if [[ -o interactive && -z "$TMUX" ]]; then
  cat << 'GREETING'
                                       .
                                   -===----==-.
                                 =+:         .=+:
                               .*-    -+-    :  +=
                               %-    +###-  *#%. +-
                              =*.    *###-  *##= .%
                              %:     .=+:   .++.  +-
                             =*.                  =*=:
                            :%:                    %
                           :%:     .             : +-
                         .+*:     -.      ..     - -+
                        =*-    .==.      .=     := .#
                        %=..:=++:       -+      =:  #.
                         :---+=:.     :+=      .*  .#.
                           .-:*=...-=**=:     :*+==+-
                              .-===-:...=====+=.
                              ..................


                              welcome back nerd

GREETING
fi
