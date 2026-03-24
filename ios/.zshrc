export PATH="$PATH":"$HOME/.pub-cache/bin"
export PATH="$PATH:$HOME/fvm/default/bin"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[[ -f /Users/admin/.dart-cli-completion/zsh-config.zsh ]] && . /Users/admin/.dart-cli-completion/zsh-config.zsh || true
## [/Completion]

alias pip=pip3
export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"
export PATH="/usr/local/opt/openjdk@17/bin:$PATH"


