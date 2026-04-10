#!/bin/bash
# start-juku-flutter.sh — Juku-Flutter Claude Code wrapper with auto-restart
# Restarts Claude Code automatically if it exits unexpectedly (rate limit, credit exhaustion, crash)
# Does NOT restart if Claude Code exited intentionally (handover complete)

PROJECT_DIR="$HOME/Documents/Claude/Projects/Juku-Flutter"
BUILDER_DIR="$HOME/Documents/Claude/Projects/The-Builder"
FLAG_FILE="$PROJECT_DIR/.claude/session_done"
RETRY_DELAY=300  # 5 minutes between retries
MAX_RETRIES=48   # max 48 retries = 4 hours of trying

cd "$PROJECT_DIR" || { echo "[JUKU-FLUTTER] ERROR: Project dir not found"; exit 1; }

notify() {
  osascript -e "display notification \"$1\" with title \"[JUKU-FLUTTER]\" sound name \"Glass\"" 2>/dev/null || true
}

echo "[JUKU-FLUTTER] Auto-restart wrapper started at $(date)"
notify "Wrapper started — Claude Code launching"

attempt=0

while [ $attempt -lt $MAX_RETRIES ]; do
  # Clear the intentional exit flag before each run
  rm -f "$FLAG_FILE"

  echo ""
  echo "[JUKU-FLUTTER] ▶ Starting Claude Code session (attempt $((attempt + 1))) at $(date)"

  # Start Claude Code with Skill Mode context
  echo "Read ~/Documents/Claude/Projects/The-Builder/SkillMode/CLAUDE.md, then HANDOVER.md, then SPRINT.md. Resume building from where the last session left off. Commit and push after each task. Notify Dispatch [SKILL MODE] after each task." | claude --remote-control --dangerously-skip-permissions --add-dir "$BUILDER_DIR"
  EXIT_CODE=$?

  echo "[JUKU-FLUTTER] Claude Code exited with code $EXIT_CODE at $(date)"

  # Check if this was an intentional exit (Claude Code wrote the flag)
  if [ -f "$FLAG_FILE" ]; then
    echo "[JUKU-FLUTTER] ✅ Intentional exit detected — not restarting"
    notify "Session ended cleanly. Not restarting."
    rm -f "$FLAG_FILE"
    exit 0
  fi

  # Unexpected exit — rate limit, credits, crash
  attempt=$((attempt + 1))

  if [ $attempt -ge $MAX_RETRIES ]; then
    echo "[JUKU-FLUTTER] ❌ Max retries reached. Giving up."
    notify "❌ Max retries reached — manual restart needed"
    exit 1
  fi

  echo "[JUKU-FLUTTER] ⚠ Unexpected exit (code $EXIT_CODE) — retrying in ${RETRY_DELAY}s..."
  notify "⚠ Session ended unexpectedly — restarting in 5 min"

  sleep $RETRY_DELAY
done
