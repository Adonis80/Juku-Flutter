// XP rewards
const int xpCreateLesson = 10;
const int xpUpvoteReceived = 4;
const int xpDailyAction = 5;
const int xpCombo3 = 5;
const int xpCombo5 = 10;
const int xpChatUpvoted = 3;

// Level thresholds
int xpForLevel(int level) {
  if (level <= 10) return 100;
  if (level <= 30) return 250;
  return 500;
}

// Rank thresholds
String rankForLevel(int level) {
  if (level >= 100) return 'mythic';
  if (level >= 50) return 'diamond';
  if (level >= 25) return 'gold';
  if (level >= 10) return 'silver';
  return 'bronze';
}

// Rank display names
const Map<String, String> rankLabels = {
  'bronze': 'Bronze',
  'silver': 'Silver',
  'gold': 'Gold',
  'diamond': 'Diamond',
  'mythic': 'Mythic',
};
