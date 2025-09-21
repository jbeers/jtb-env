# workbench header: See workbench/CodeHeader.txt for details

# Find the nearest git repository
git_root=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$git_root" ]; then
  echo "No git repository found."
  exit 1
fi

# Change to the git root directory
cd "$git_root"

# Parse --ref argument
ref="HEAD"
log_limit="-n 5"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ref)
      ref="$2"
      # If ref is "available", set log_limit to "" and ref to HEAD..@{u}
      if [[ "$ref" == "available" ]]; then
        log_limit=""
        ref="HEAD..@{u}"
      # If ref is an integer, treat it as a limit for -n
      elif [[ "$ref" =~ ^[0-9]+$ ]]; then
        log_limit="-n $ref"
        ref="HEAD"
      fi
      shift 2
      ;;
    *)
      break
      ;;
  esac
done

# Get the log of incoming changes (those that would be pulled in)
git_log=$(git --no-pager log $log_limit "$ref" --pretty=format:"%C(yellow)%h %C(cyan)%ad %C(green)%an%C(reset)%n    %s%n%n" --date=short)

# The log is now in $git_log for further processing

# Determine the command to process git_log
if [ -n "$1" ]; then
  process_cmd="$1"
elif [ -n "$GIT_LOG_CMD" ]; then
  process_cmd="$GIT_LOG_CMD"
else
  process_cmd="local"
fi

system_prompt="The following content is a git log of incoming changes. Output both the first and last name of one contributer. No other text."
system_prompt="
 The following content is a git log of incoming changes.
 Review the changes and creat a short story. Follow these instructions.

 * No more than 3 paragraphs
 * Use the commit authors as characters in the story
 * Make it fun and engaging
 * The purpose of the commits should be the plot of the story
"
git_log_sanitized=$(echo "$git_log" \
  | tr -d '\000-\011\013\014\016-\037' \
  | sed 's/"/\\"/g' \
  | awk '{printf "%s\\n", $0}' \
  | iconv -f UTF-8 -t UTF-8//IGNORE \
)

myvar=$(echo '{
    "model": "hermes-3-llama-3.2-3b",
    "messages": [
      { "role": "system", "content": "'"$system_prompt"'" },
      { "role": "user", "content": "'"$git_log_sanitized"'" }
    ],
    "temperature": 0.7,
    "max_tokens": -1,
    "stream": false
  }')

tempfile=$(mktemp /tmp/git_log_summary.XXXXXX)
echo "$myvar" > $tempfile


# Pipe git_log into the chosen command
if [ -z "$process_cmd" ] || [ "$process_cmd" = "local" ]; then
  curl -s http://localhost:1234/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d @"$tempfile" | jq -r '.choices[0].message.content'
else
  echo "$git_log" | eval "$process_cmd"
fi

