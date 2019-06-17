# Place this in your ~/.bashrc file

function log() {
  /home/wes/code/shelltalk/client.py -W "$$" "$(history 1)" > /dev/null 2>&1 & disown "$!"
}

/home/wes/code/shelltalk/client.py -S $$

export PROMPT_COMMAND="$PROMPT_COMMAND; log"
