#!/bin/bash

# CONFIGURATION
MAX_LOOPS=15
STOP_SIGNAL="ALL_FEATURES_COMPLETE"

# COUNTER
count=1

PROMPT='You are building the Cyclops macOS app. Read CLAUDE.md for constraints and build commands.

1. Call mcp__conductor__get_next_feature(projectName: "cyclops") to get the next pending feature.
2. If there are no more pending features, output "ALL_FEATURES_COMPLETE" and stop.
3. Read all existing source files in Cyclops/Sources/ to understand current state.
4. Implement the feature. Write real, complete code — no placeholders.
5. Run `cd Cyclops && swift build` to verify. Fix any build errors.
6. Call mcp__conductor__mark_feature_complete with the feature ID.
7. Commit the changes with a descriptive message.
8. Call mcp__conductor__get_project_status(projectName: "cyclops") and report progress.'

echo "Starting Cyclops Conductor Loop (Max: $MAX_LOOPS)..."

while [ $count -le $MAX_LOOPS ]; do
  echo ""
  echo "=================================================="
  echo "Iteration: $count / $MAX_LOOPS"
  echo "=================================================="

  output=$(claude --dangerously-skip-permissions -p "$PROMPT")

  echo "$output"

  # Check if all features are complete
  if echo "$output" | grep -q "$STOP_SIGNAL"; then
    echo ""
    echo "All features complete. Stopping."
    exit 0
  fi

  ((count++))

  # Cool down to prevent rate limits
  sleep 2
done

echo "Max loops reached."
