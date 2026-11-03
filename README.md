<p align="center">
  <img src="assets/brand/mark.svg" width="142" height="142" alt="Tong Ledger gold ledger monogram" />
</p>
<h1 align="center">TONG LEDGER</h1>
<p align="center"><strong>YOUR MONEY. YOUR RULES.</strong><br/>
  Premium open-source money manager & budget planner • By ParmTech
</p>

**Tong Ledger by ParmTech** is a free, open-source, offline-first personal finance and budget planner with a luxury-inspired experience. **Android is the first release target**; Flutter keeps the business logic portable to iOS, Windows, macOS and Linux for later releases.

> **Current status: v0.3 ANDROID DEVELOPMENT / NOT A PUBLIC RELEASE.** There is a verified debug APK, but secure recovery, complete accounting and real-device QA are unfinished. Use fictional data only. The **v2 blueprint is a future target**, not a claim its features work today.

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
| [Wiki start page](docs/WIKI_HOME.md) | Project overview and introduction |
| **[Master blueprint v2](docs/MASTER_BLUEPRINT_V2.md)** | **Canonical audited A-to-Z plan for all future work** |
| [Audit: flaws & fixes](docs/BLUEPRINT_AUDIT_2026_11_03.md) | Risk priorities and practical corrections |
| [UX and luxury app design v2](docs/UX_INFORMATION_ARCHITECTURE_V2.md) | Screen-by-screen flow, wireframes, colours and interaction patterns |
| [Financial domain v2](docs/FINANCIAL_DOMAIN_V2.md) | Correct accounting, cards, loans, as-of and stable categories |
| [Engineering roadmap v2](docs/ENGINEERING_ROADMAP_V2.md) | Secure recovery, modular build plan, rollout gates |
| [Original v0.1 blueprint](docs/MASTER_BLUEPRINT.md) | Historical feature brief (not canonical) |
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
