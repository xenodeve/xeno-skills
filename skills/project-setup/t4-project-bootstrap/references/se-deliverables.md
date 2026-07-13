# SE Deliverables — the optional 7-phase Software-Engineering document set

## Overview

A 7-phase Software-Engineering deliverable package that walks a project from planning through requirements, design, internal process, testing, deployment, and quality evaluation — the standard chapter structure of an academic SE course paper or a formal agency dossier. Anchored by a phase index and a supporting UML report, each phase maps to one paper chapter.

**This set is OPTIONAL.** Produce it only when a formal document deliverable is required (academic submission, or a client contract demanding a full SE dossier). Everyday feature work does not need it — the governance layer + templates in the other references cover normal development. All diagrams below are Mermaid so they render in GitHub/Obsidian.

Files live under `Documents/Software Engineer/`: `SE_PHASE_INDEX.md`, `SE_PHASE1..7_*.md`, `UML_REPORT.md`.

## SE_PHASE_INDEX skeleton

```markdown
# <PROJECT_NAME> Software Engineering Documents

<1-2 sentence note: docs split by phase to keep analysis / design / operations separate.>

## Document Index
1. SE_PHASE1_PROJECT_PLAN_AND_GANTT.md      — project planning
2. SE_PHASE2_SRS_AND_SYSTEM_ANALYSIS.md     — requirements + system analysis
3. SE_PHASE3_DIALOGUES_AND_PROTOTYPE.md     — user interaction + prototype
4. SE_PHASE4_INTERNAL_DOCUMENTATION.md      — internal docs + version control
5. SE_PHASE5_TEST_SPECIFICATION_AND_UAT.md  — testing + UAT
6. SE_PHASE6_DEPLOYMENT_AND_GO_LIVE.md      — deployment + manuals
7. SE_PHASE7_QUALITY_ASSESSMENT_AND_PROCESS_EVIDENCE.md — evaluation + process evidence

## Supporting Documents
- UML_REPORT.md  (supports Phase 2 & 3)
- <per-subsystem doc indexes: FRONTEND / BACKEND / <SERVICE>>

## Suggested Usage in Paper
- Phase 1 → Project Planning chapter
- Phase 2 → Requirement Analysis + System Design chapter
- Phase 3 → Prototype + User Interaction chapter
- Phase 4 → Internal Process / Documentation / Version Control chapter
- Phase 5 → Testing + UAT chapter
- Phase 6 → Deployment / Installation / Operation chapter
- Phase 7 → Evaluation / Satisfaction / Process Quality chapter
```

## Per-phase outline

### Phase 1 — Project Plan and Gantt Chart
*Delivers:* a PMBOK-flavored project plan, milestone list, and a Gantt chart.
- 1. Project Overview — `<one-paragraph system description + subsystem list>`
- 2. Project Objectives — numbered goals
- 3. Project Scope — **In Scope** / **Out of Scope** bullet lists
- 4. PMBOK-Oriented Planning — 4.1 Scope, 4.2 Schedule, 4.3 Resource, 4.4 Risk management
- 5. Project Milestones — table `| Milestone | Deliverable |` (M1…M7, one per phase)
- 6. Gantt Chart — Mermaid `gantt` block, sections = phase groups, `<start-date>`/`<duration>` per phase
- 7. Expected Deliverables — numbered list (the 7 phase outputs)
- 8. Summary

### Phase 2 — Software Requirement Specification & System Analysis
*Delivers:* an IEEE-style SRS plus analysis artifacts (fishbone, DFD, data dictionary).
- 1. Introduction — 1.1 Purpose, 1.2 Scope, 1.3 Definitions (`<glossary terms>`)
- 2. Problem Analysis — Fishbone/Ishikawa (Mermaid `flowchart`, categories: Data / Integration / UX / Process / Technology → `<core problem>`)
- 3. Product Perspective — narrative of system positioning/architecture
- 4. Functional Requirements — numbered `<FR>` list
- 5. Non-Functional Requirements — numbered `<NFR>` list (idempotency, observability, resilience, …)
- 6. System Design Artifacts — 6.x Context-level **DFD** (Mermaid), 6.x **Data Dictionary** table `| Entity | Field | Description |`

### Phase 3 — Dialogues Diagram and Prototype
*Delivers:* user-interaction dialogue flows + a clickable prototype description.
- 1. Purpose
- 2. Main User Dialogue Flows — one Mermaid `flowchart` per key flow (`<flow-1>`, `<flow-2>`, `<flow-3>`)
- 3. Prototype Scope — numbered list of prototyped screens/pages
- 4. Prototype Description — narrative (component-based, responsive, modal-vs-page, interaction states)
- 5. Relationship with UML — pointer to use-case / sequence / activity diagrams in UML_REPORT
- 6. Summary

### Phase 4 — Internal Documentation and Versioning Control
*Delivers:* internal-docs inventory + Git version-control conventions.
- 1. Objectives of Phase 4
- 2. Internal Documentation — narrative + list of doc categories, links to subsystem doc indexes
- 3. Document Types table — `| Doc Type | Purpose | Example Content |` (Architecture / Module / API / Setup / Deployment / Maintenance) + mapping to real files
- 4. Versioning Control — Git principles (repo, branching, commit hygiene, pre-merge review, tags/releases)
- 5. Branch & Commit Naming — `feature/…`, `fix/…`, `refactor/…`, `docs/…`; conventional-commit examples
- 6. Benefits — numbered list
- 7. Summary

### Phase 5 — Test Specification and UAT
*Delivers:* test spec tables, UAT criteria + results, defect log.
- 1. Test Objectives
- 2. Test Scope — bullet list of feature areas
- 3. Test Specification Table — `| Test ID | Test Item | Expected Result |` (`TC-01…`)
- 4. UAT Criteria — numbered acceptance conditions
- 5. Sample UAT Result Summary — `| UAT Case | Result | Remark |`
- 6. Defect Recording — `| Defect ID | Description | Severity | Status |`
- 7. Summary

### Phase 6 — Deployment Plan, Go-Live Preparation, and Manuals
*Delivers:* deployment plan, go-live checklist, install/user/operation manuals.
- 1. Deployment Objectives
- 2. Hardware & Software Preparation — **Hardware** list / **Software** list
- 3. Go-Live Checklist — numbered pre-launch checks + expected local ports per service
- 4. Installation Guide Summary — per-subsystem install steps + doc links
- 5. User Manual Summary — numbered end-user how-tos
- 6. System Operation Manual Summary — numbered admin/ops procedures (start/stop, logs, health, config, failure handling)
- 7. Summary

### Phase 7 — Quality Assessment and Process Evidence
*Delivers:* user-satisfaction questionnaire + process-quality evidence (CMMI/OWASP), defect-resolution log.
- 1. User Questionnaire Objective
- 2. Example Questionnaire Topics — numbered list
- 3. Example Evaluation Table — `| Evaluation Item | Score Range |` (1–5 Likert)
- 4. Process Evidence Alternatives — 4.1 **CMMI-oriented** evidence, 4.2 **OWASP-oriented** security checklist, 4.3 **Defect Recording & Resolution Log** `| Defect ID | Description | Root Cause | Resolution | Impact |`
- 5. Sample Result Summary — narrative write-up of findings
- 6. Summary

## UML report skeleton

A single supporting doc collecting the project's core UML diagrams (all Mermaid), supporting Phases 2–3:

1. **Use Case Diagram** — actors (`<Guest>`, `<Member>`) → use cases, with `include`/`extend` relations.
2. **Component Diagram** — high-level runtime components (frontend, backend, services, external APIs, stores) and their connectors.
3. **Package Diagram** — backend module/package structure and dependencies (Mermaid `classDiagram`).
4. **Class Diagram** — core services/interfaces with key methods and relationships.
5. **Sequence Diagram** — one end-to-end flow of the system's signature feature (actor → FE → BE → service → external).
6. **Deployment Diagram** — physical/container topology; optionally a second variant for target production topology.

> The reference set uses Use-case, Component, Package, Class, Sequence, and Deployment. It does **not** include standalone ER, state, or activity diagrams — activity/interaction coverage folds into the Phase-3 dialogue flowcharts, and data structure is captured by the Phase-2 data dictionary. Add ER/state/activity diagrams here if the new project's grading rubric requires them.
