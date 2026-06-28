# Nala Mobile Design System

## Direction

Nala uses a clean, modern iOS-inspired interface while retaining Flutter
Material components for accessibility and platform compatibility.

## Foundations

- Background: `#F5F5F7`
- Surface: `#FFFFFF`
- Primary brand/action: `#F5961A`
- Secondary brand/expense: `#DB1E09`
- Primary text: `#111318`
- Secondary text: `#747B87`
- Border: `#E5E7EB`
- Card radius: `16`
- Control radius: `14`
- Typeface: Inter Tight, used as a license-safe approximation of the compact
  hierarchy and proportions associated with Apple's SF Pro interface type.

## Brand Asset

The primary application logo is `img/Nala baru2.png`. It is used on splash,
onboarding, login, and registration surfaces. Because the source image has a
white canvas, it should be displayed on white or light neutral backgrounds.

## Interaction Rules

- Use one clear primary action per surface.
- Do not display controls that have no implemented behavior.
- Use icon buttons for navigation and compact commands.
- Prefer subtle borders over decorative drop shadows.
- Keep existing content visible during background refreshes.
- Use a sliding segmented control for mutually exclusive form modes.
- Use the shared `AppTheme` rather than defining local form and button styles.

## Applied Areas

The shared theme covers app bars, typography, inputs, buttons, cards, dialogs,
bottom sheets, snack bars, progress indicators, and navigation. Targeted
screen updates align authentication, dashboard, transaction forms, profile,
health, reports, chat, wallets, budgets, and recurring bills with the same
visual language.
