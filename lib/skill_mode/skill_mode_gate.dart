/// Domain + tenant access check for Skill Mode.
/// Skill Mode is only available to users in the Language domain.
/// White-label tenants can disable it via enabled_features.
bool canAccessSkillMode({
  required String? activeDomain,
  Map<String, dynamic>? tenantEnabledFeatures,
}) {
  final domainMatch = activeDomain == 'languages';
  final tenantAllows =
      tenantEnabledFeatures == null ||
      (tenantEnabledFeatures['skill_mode'] as bool? ?? true);
  return domainMatch && tenantAllows;
}
