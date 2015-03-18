. ~/.config/aliases

function fish_user_key_bindings
  bind . 'expand-dot-to-parent-directory-path'
  bind \cs 'sudo-my-prompt-yo'
end

if test -d $HOME/.rbenv
  set PATH $HOME/.rbenv/bin $PATH
  . (rbenv init -|psub)
end

# Postgres.app CLI tools
if test -d /Applications/Postgres.app
  set PATH /Applications/Postgres.app/Contents/MacOS/bin $PATH
end
if test -d /Applications/Postgres.app/Contents/Versions/9.3/bin
  set PATH /Applications/Postgres.app/Contents/Versions/9.3/bin $PATH
end

# homedirectory bin folder
if test -d ~/.dotfiles/bin
  set PATH $PATH ~/.dotfiles/bin
end

set -l uname (uname -a | sed -e 'y/ /\n/')
if contains "Linux" $uname
  #echo "system: linux"
  alias ls="command ls -la --color=auto"
  alias ll="command ls -l --color=auto"
else if contains "Darwin" $uname
  #echo "system: darwin"
  alias ls="command ls -la -G"
  alias ll="command ls -l -G"
else
  echo "could not detect operating system"
end

function cs -d "Change directory then ls contents"
  cd $argv; and ls
end

alias cld="cd (command ls -t | head -n1)"

function _git_hash
  echo -n (git log -1 ^/dev/null | sed -n -e 's/^commit \([a-z0-9]\{8\}\)[a-z0-9]\{32\}/\1/p')
end

function _hostname
  echo (hostname ^&- | cut -d . -f 1)
end

function _env_vars
  if set -q RAILS_ENV
    echo -n $RAILS_ENV
  end

  if set -q RAILS_ENV NODE_ENV
    echo -n " "
  end

  if set -q NODE_ENV
    echo -n $NODE_ENV
  end

  if set -q TEST
    echo -n " "
    echo -n (basename $TEST)
  end
end

function _prompt_character
  switch $USER
  case root
    echo '#'
  case '*'
    echo '>'
  end
end

function fish_prompt
  set -l previous_command $status
  set -l stats (gitstatus)
  set -l vars (_env_vars)
  set -l hash (_git_hash)

  set -l dirty (math $stats[3] + $stats[2] + $stats[4])

  # previous command status if nonzero
  if test $previous_command -gt 0
    echo -s -n (set_color -b red) status: " "  $previous_command (set_color normal) " "
  end

  # ! for modified files
  if test $dirty -gt 0
    echo -s -n (set_color red) ! (set_color normal)
  end

  # branch name
  if test $stats[1]
    echo -s -n (set_color cyan) $stats[1] " " (set_color normal)
  end

  # environment vars
  if test $vars
    echo -s -n (set_color purple) " " $vars (set_color normal)
  end

  # hidden data
  echo -s -n (set_color black)

  # current sha hash
  if test $hash
    echo -s -n (_git_hash) " "
  end

  echo -s -n (date "+%b-%d %H:%M:%S")
  echo -s -n (set_color normal)

  # prompt line
  echo -s (set_color normal)

  if test $USER = 'root'
    echo -s -n (set_color -o magenta) $USER (set_color normal) @
  end

  echo -s -n (_hostname) " "

  echo -s -n (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
  echo -s -n (_prompt_character) " "
end

function tab -d "Open a new tab and run a command in that tab."
  osascript             -e 'tell application "System Events"' \
                          -e 'tell process "Terminal" to keystroke "t" using command down' \
                        -e 'end'
  osascript             -e 'tell application "Terminal"' \
                          -e 'activate' \
                          -e "do script with command \"cd $PWD\" in window 1" \
                        -e 'end tell'

  for current_arg in $argv
    osascript             -e 'tell application "Terminal"' \
                            -e 'activate' \
                            -e "do script with command \"$current_arg\" in window 1" \
                          -e 'end tell'
  end

end

function workflow -d "Start up my standard rails workflow"
  tab rc
  test -f Guardfile; and tab guard
  tab
  if not contains "!v" $argv
    mvim . 2>/dev/null
  end
  rs
end

function gloo -d "Start up the Gloo vm and related tools"
  cd ~/Sites/gloo/program_creator
  tab rs
  tab rc
  tab "rake QUEUE=\\\* VERBOSE=1 resque:work"
  tab "rake resque:scheduler"
  tab "cd ../bfd/api-analytics" "play run"
  exit
end

function backend -d "Start up the gloo bfd infrastructure"
  cd ~/Sites/gloo/bfd
  tab "redis-server /usr/local/etc/redis.conf"
  tab "elasticsearch -f -D es.config=/usr/local/opt/elasticsearch/config/elasticsearch.yml"
  tab "cd ~/Sites/gloo/kafka-0.7.2-incubating-src" "bin/zookeeper-server-start.sh config/zookeeper.properties"
  tab "cd ~/Sites/gloo/kafka-0.7.2-incubating-src" "bin/kafka-server-start.sh config/server.properties"
  exit
end

function notes -d "show the notes file"
  test -f ~/notes.md; and less ~/notes.md
end

function keyme
#
# For use when resuming remote screen session to re-sync
# ssh agent, and thus keys push through the new ssh session
# and make them available to shells running inside of screen
#
# Run before connecting to screen to dump env vars to a file,
# then resume or extend screen session and run again to
# import those env vars to the current environment.
#
  if test $TERM = "screen"
    echo -n "Importing ssh agent - "
    if test -f $HOME/.ssh/envs
      . $HOME/.ssh/envs
      echo "Success!"
    else
      echo "No envs file found."
    end
  else
    echo -n "Exporting ssh agent - "
      # Adapted for fish from http://www.deadman.org/sshscreen.php
      echo > ~/.ssh/envs
      for x in SSH_CLIENT SSH_TTY SSH_AUTH_SOCK SSH_CONNECTION DISPLAY
          echo set $x (eval "echo \$$x") >> ~/.ssh/envs
      end

      echo "Success!"
  end
end

function keycopy -d "Copy public key to server"
  cat ~/.ssh/id_rsa.pub | ssh $argv 'sh -c "mkdir -p .ssh; cat >> .ssh/authorized_keys && echo public key copied"'
end
