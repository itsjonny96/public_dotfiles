#!/bin/bash
export PATH="/opt/homebrew/bin:$PATH"

output=$(task add $1 2>&1)
rc=$?

if [ $rc -eq 0 ]; then
  osascript -e "display notification \"$output\" with title \"✅ Task Added\" subtitle \"Success\""
else
  osascript -e "display notification \"$output\" with title \"❌ Task Failed\" subtitle \"Error\""
fi
