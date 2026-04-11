Perform a systematic bug hunt on the feature just built. Do every step — do not skip:

1. **Static analysis:** `flutter analyze --no-pub` — fix ALL warnings, not just errors.
2. **Tests:** `flutter test --no-pub` — fix ALL failing tests.
3. **Null safety audit** — check every new file for missing null checks on nullable types.
4. **Async error handling** — verify every async call has error handling. No silent failures.
5. **Widget dispose** — check every StatefulWidget that uses streams, controllers, or timers disposes them in `dispose()`.
6. **Gamification edge cases:**
   - What happens at Level 0 and max level?
   - What happens at 0 XP and max XP?
   - What happens if streak is 0?
   - What happens if user has no Juice balance?
7. **RLS check** — any new Supabase tables must have RLS enabled. Verify in migration file.
8. **No secrets** — `grep -r "sk_live\|pk_live\|supabase_key\|AZURE" lib/` must return nothing.

For every issue found: state what it is, fix it, confirm with a passing test or analyzer result.
Report final verdict: CLEAN or ISSUES REMAIN (with list).
