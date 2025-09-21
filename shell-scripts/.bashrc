

function git-ai-summary-remote() {
    source <(curl -sSL "https://github.com/jbeers/jtb-env/blob/main/shell-scripts/git-ai-summary.sh?raw=true") "$@"
}

alias git-what-changed='git --no-pager log  --since="1 weeks ago" \
  --pretty=format:"%C(yellow)%h %C(cyan)%ad %C(green)%an%C(reset)%n    %s%n%n" \
  --date=short'
