---
name: project-landscape
description: Provides a map of all local projects, their tech stacks, dependencies, and inter-system relationships. Use when the user asks about project architecture, cross-repo dependencies, how systems connect, which repo owns what, or needs to explore another codebase. Also use when the user mentions Gusto, Guideline, Zenpayroll, mobile-app, mb-ios, or asks "where does X live?"
---

# Project Landscape

All projects live in `~/Developer/`. This skill documents the system context (C1), tech stacks, and how to explore across repos.

## C1 Context Diagram

```mermaid
C4Context
    title System Context Diagram — Guideline & Gusto

    Person(employer, "Employers", "Companies offering retirement benefits")
    Person(participant, "Participants", "Employees enrolled in retirement plans")
    Person(gustoAdmin, "Gusto Admins", "Gusto internal operations")
    Person(glAdmin, "Guideline Admins", "Guideline internal operations")

    Enterprise_Boundary(gl, "Guideline Platform") {
        System(app, "app", "Guideline Monorepo<br/>Rails + React/TS (Nx)<br/>github.com/guideline-app/app")
        System(mobileApp, "mobile-app", "Guideline Mobile App<br/>React Native / Expo<br/>github.com/guideline-app/mobile-app")
    }

    Enterprise_Boundary(gusto, "Gusto Platform") {
        System(zenpayroll, "Zenpayroll", "Gusto Backend<br/>Rails monolith<br/>github.com/Gusto/zenpayroll")
        System(mbIos, "mb-ios", "Gusto iOS App<br/>Swift / Xcode<br/>github.com/Gusto/mb-ios")
    }

    System_Ext(drivewealth, "DriveWealth", "Brokerage provider")
    System_Ext(apex, "Apex", "Custodian")
    System_Ext(payments, "Payment Processors", "Banks, tax agencies, benefits providers")

    Rel(employer, app, "Manages plans via web")
    Rel(participant, app, "Enrolls, contributes via web")
    Rel(participant, mobileApp, "Mobile access")
    Rel(gustoAdmin, zenpayroll, "Manages payroll")
    Rel(glAdmin, app, "Admin operations")

    Rel(mobileApp, app, "GraphQL API")
    Rel(app, zenpayroll, "Payroll data sync, employer/participant integrations")
    Rel(zenpayroll, app, "Webhooks, retirement plan management")
    Rel(mbIos, zenpayroll, "REST/GraphQL API")

    Rel(app, drivewealth, "Brokerage operations")
    Rel(app, apex, "Custodian operations")
    Rel(zenpayroll, payments, "Payroll processing")

    UpdateLayoutConfig($c4ShapeInRow="3", $c4BoundaryInRow="2")
```

### Key Relationships

| From | To | Integration |
|------|----|-------------|
| `mobile-app` | `app` | GraphQL API (mobile client → Guideline backend) |
| `app` (React) | `app` (Rails) | GraphQL + REST (same monorepo, frontend → backend) |
| `app` | `Zenpayroll` | Payroll data sync, employer/participant integrations |
| `mb-ios` | `Zenpayroll` | REST/GraphQL API (iOS client → Gusto backend) |
| `Zenpayroll` | `app` | Webhooks, API calls for retirement plan management |

## Project Registry

### app — Guideline Monorepo

| Property | Value |
|----------|-------|
| **Path** | `~/Developer/app` |
| **Repo** | [guideline-app/app](https://github.com/guideline-app/app) |
| **Stack** | Ruby on Rails (backend) + React/TypeScript in Nx monorepo (frontend) |
| **Databases** | 12+ (primary, accounting, ledger, payroll_platform, etc.) |
| **Testing** | Minitest (backend), Vitest (frontend) |
| **Jobs** | Sidekiq, Karafka (Kafka) |
| **Org** | Engines (`defcon/`, `ira/`, `custodial/`) + Subsystems (`auth/`, `billing/`, etc.) |
| **Key dirs** | `app/`, `client/`, `engines/`, `subsystems/`, `lib/`, `config/` |
| **Has AGENTS.md** | Yes — read it for full dev commands and architecture |

### mobile-app — Guideline Mobile App

| Property | Value |
|----------|-------|
| **Path** | `~/Developer/mobile-app` |
| **Repo** | [guideline-app/mobile-app](https://github.com/guideline-app/mobile-app) |
| **Stack** | React Native (Expo), TypeScript |
| **Runtime** | Node 24, npm |
| **Testing** | Jest / Maestro (E2E) |
| **GraphQL** | Codegen against `app` backend schema |
| **Key dirs** | `src/`, `app/`, `e2e/` |

### Zenpayroll — Gusto Backend

| Property | Value |
|----------|-------|
| **Path** | `~/Developer/Zenpayroll` |
| **Repo** | [Gusto/zenpayroll](https://github.com/Gusto/zenpayroll) |
| **Stack** | Ruby on Rails monolith, Ruby 3.4 |
| **Frontend** | JS/TS (Yarn 4) |
| **Typed** | Sorbet (`sorbet/`) |
| **Key dirs** | `app/`, `packs/`, `components/`, `lib/`, `config/`, `js/` |

### mb-ios — Gusto iOS App

| Property | Value |
|----------|-------|
| **Path** | `~/Developer/mb-ios` |
| **Repo** | [Gusto/mb-ios](https://github.com/Gusto/mb-ios) |
| **Stack** | Swift, Xcode |
| **Architecture** | Modular Swift packages (AddressKit, GustoLoginKit, GustoBenefits, etc.) |
| **Key dirs** | `Gus/`, `AddressKit/`, `GustoLoginKit/`, `FeatureCoordination/` |

## Exploring Other Codebases

When the user asks about code in a different repo, or you need cross-repo context:

### 1. Read files directly

All repos are local. Use absolute paths:

```
~/Developer/mobile-app/src/...
~/Developer/Zenpayroll/app/...
~/Developer/mb-ios/Gus/...
~/Developer/app/engines/...
```

### 2. Search across repos

Use Grep or Glob with the target repo path:

- Search Zenpayroll for an API endpoint: `Grep pattern="def some_action" path="~/Developer/Zenpayroll/app"`
- Find a Swift file in mb-ios: `Glob pattern="**/*ViewModel.swift" target_directory="~/Developer/mb-ios"`
- Search mobile-app for a screen: `Grep pattern="SomeScreen" path="~/Developer/mobile-app/src"`

### 3. Check AGENTS.md / CLAUDE.md first

Before deep-diving into another repo, check for setup docs:

```
~/Developer/<repo>/AGENTS.md
~/Developer/<repo>/CLAUDE.md
~/Developer/<repo>/README.md
```

These contain dev commands, architecture overviews, and testing instructions specific to that repo.

### 4. Use subagents for deep exploration

For thorough cross-repo investigation, launch an `explore` subagent scoped to the target repo directory. This avoids polluting the current conversation context.

## Common Cross-Repo Tasks

| Task | Where to look |
|------|---------------|
| GraphQL schema that mobile-app consumes | `~/Developer/app/app/graphql/` |
| How Gusto sends payroll data to Guideline | `~/Developer/Zenpayroll/` for sender, `~/Developer/app/engines/payroll/` for receiver |
| How mobile-app authenticates | `~/Developer/mobile-app/src/` for client, `~/Developer/app/subsystems/auth/` for backend |
| Gusto iOS feature modules | `~/Developer/mb-ios/` — each module is a Swift package directory |
| Guideline 401(k) engine | `~/Developer/app/engines/defcon/` |
| Guideline IRA engine | `~/Developer/app/engines/ira/` |
