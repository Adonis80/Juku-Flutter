Write a complete session handoff. Do this in order:

1. **Run quality gates:**
   - `dart format . --set-exit-if-changed`
   - `flutter analyze --no-pub`
   - `flutter test --no-pub`
   Report: PASS or FAIL for each.

2. **Update SPRINT.md** — mark completed tasks ✅, update in-progress.

3. **Write HANDOVER.md** (The-Builder section) with:
   - What was completed this session (bullet list)
   - Current test status
   - Any blockers requiring human decision (add to 🔴 section below)
   - Next recommended task

4. **Update DECISIONS.md** — log any non-trivial technical decisions made this session.

5. **Commit everything:**
   ```bash
   git add -A && git commit -m "feat: [describe what was built]" && git push origin main
   ```

6. **Dispatch notification:** `[JUKU] ✅ Session complete — [one-line summary]`

NEVER skip the git push. NEVER mark done if tests are red.
