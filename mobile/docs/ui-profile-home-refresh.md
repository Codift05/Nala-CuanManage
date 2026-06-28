# Home and Profile UI Refresh

## Summary

- Standardized application typography with Inter Tight.
- Reworked the Home header around NALA features, including financial health
  score and notifications.
- Simplified Profile navigation by removing redundant labels and descriptions.
- Standardized empty avatars with a neutral user icon while preserving uploaded
  profile photos.
- Kept all existing wallet, security, recurring bill, and logout actions.

## Verification

- `flutter analyze` passes for the changed Home and Profile screens.
- Flutter widget and formatter tests pass.
