#!/bin/bash
export PATH="/opt/homebrew/bin:$PATH"

if [ "$action" = "add" ]; then
  [ -z "$uri" ] && exit 0
  args=("save" "$uri")
  [ -n "$title" ] && args+=("--title" "$title")
  [ -n "$tags" ] && args+=("--tags" "$tags")
  if bmm "${args[@]}" 2>&1; then
    osascript -e "display notification \"$uri\" with title \"Bookmark saved\""
  else
    osascript -e "display notification \"Failed to save bookmark\" with title \"bmm error\""
  fi
else
  uri="$1"
  case "$browser" in
    chrome)  open -a "Google Chrome" "$uri" ;;
    safari)  open -a "Safari" "$uri" ;;
    *)       open "$uri" ;;
  esac
fi
