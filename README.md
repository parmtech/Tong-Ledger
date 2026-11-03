# Tong Ledger

### Your Money. Your Rules.

**Tong Ledger by ParmTech** is a free, open-source, offline-first personal finance and budget planner with a luxury-inspired experience. **Android is the first release target**; Flutter keeps the business logic portable to iOS, Windows, macOS and Linux for later releases.

> **Current status: FOUNDATION / DEVELOPMENT.** No production APK or live banking service exists yet. Sample data and experimental UI are NOT a secure place for real financial records. Release only after encryption, persistence, testing and Play Store compliance gates are complete.

## What Tong Ledger will manage

- **Banks & institutions:** manually create a bank, then unlimited salary, everyday and savings accounts under it.
- **Credit cards:** link to the issuing bank, track limit, amount owed, available credit and due date. The limit is not cash.
- **Loans:** car, home, personal or private-company lenders; bank association is optional. Loans have a separate unified view.
- **Assets & net worth:** property, vehicles, investments, dated valuations, separately counted liabilities.
- **Income & expenses:** salary, freelance, business, irregular pay; assign each actual transaction to a bank account or card.
- **Budget planner:** 30 genuine editable ready-made budget plans in six collections, plus fully custom budgets and goals.
- **Help & tutorials:** quick first-use guide and detailed financial-learning academy.

## Documentation / wiki

| Read first | Purpose |
| --- | --- |
| [Master blueprint](docs/MASTER_BLUEPRINT.md) | A-to-Z product scope, calculations, screens, release criteria |
| [30 budget plans](docs/BUDGET_TEMPLATES.md) | Six collections of real allocation plans |
| [Architecture](docs/ARCHITECTURE.md) | Shared domain layers and application boundaries |
| [Data model](docs/DATA_MODEL.md) | Institution/account/card/loan/ledger schema |
| [UX / luxury design system](docs/UX_DESIGN.md) | Colours, navigation, responsiveness, accessibility |
| [Tutorials](docs/ONBOARDING_TUTORIALS.md) | Two-minute quick-start and complete academy |
| [Security & privacy](docs/SECURITY_PRIVACY.md) | Threat model, encryption, disclosure and backup requirements |
| [Testing](docs/TEST_PLAN.md) | Release gate scenarios and calculation invariants |
| [Roadmap](docs/ROADMAP.md) | Android-first milestones and cross-platform follow-up |
| [Developer handoff](docs/HANDOFF.md) | Current status, blockers, future contributor instructions |

## Planned technology
Flutter / Dart, a clean domain module, fixed-point integer money, offline-first encrypted persistent store (not yet implemented), Material 3 with custom navy-and-champagne design, and GitHub Actions. The first code milestone contains domain calculations, example UI and tests; it must not be described as production-complete.

## Local development (after Flutter SDK installation)

~~~sh
flutter create --platforms=android --org au.parmtech --project-name tong_ledger .
flutter pub get
flutter analyze
flutter test
flutter run
~~~

The repository intentionally omits generated Android platform folders during initial scaffold. The command above generates them. Signing credentials must stay outside Git; production app IDs and Play Console ownership are checked before store upload.

## Contributing
Issues, documentation fixes and pull requests are welcome. Please review [CONTRIBUTING.md](CONTRIBUTING.md) and [SECURITY.md](SECURITY.md). Never post bank account details, API keys, customer data or real balances in issues. Code is licensed under Apache 2.0; content/assets require source/rights verification.

**Developed by ParmTech — Open Source.**
