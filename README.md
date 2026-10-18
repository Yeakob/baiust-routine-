# CSE Routine — BAIUST

Automated class-routine generator for the Department of Computer Science and Engineering,
Bangladesh Army International University of Science and Technology.

The Program Coordinator imports the course distribution, checks workload credits and lab
staffing, generates a conflict-free weekly routine for all eight semesters with a
constraint solver (Google OR-Tools CP-SAT), adjusts it by hand, and publishes immutable
versions. Faculty sign in to see their routine and workload, submit availability and
request changes.

```
client/     React + Vite + TypeScript + Tailwind (UI)
server/     Express + TypeScript + Mongoose (API, validation, imports, exports)
shared/     TypeScript rules shared by client and server (validation, workload, schemas)
optimizer/  Python FastAPI + OR-Tools CP-SAT (timetable solver)
docs/       Architecture, API, deployment, testing, backup, troubleshooting, Excel template
```

## What is verified on the real Fall-26 workbook

The seed loads `002. fall-26 No section merge.xlsx` through the same import pipeline users use:

| Check | Result |
|---|---|
| Workbook totals reproduced (credits / contact hours) | 293 credits (261.5 departmental + 31.5 other), 252 expected, 407 contact hours — identical to the workbook |
| Generation of all 8 semesters + service courses | 122 sessions placed, 0 faculty / student / room conflicts, 0 idle gaps |
| Lab staffing rule (> 20 students ⇒ 2 teachers) | 18 understaffed lab groups flagged; publication blocked until resolved or excepted |
| Import validation | Invalid credits, unknown faculty, unsupported types, missing codes, duplicates, count mismatches and workload discrepancies all reported per row |

Rooms are **placeholders** (8 classrooms, 5 software labs, a hardware lab, a networking lab),
because the workbook does not list rooms. Replace them with the real rooms before generating
the official routine.

## Quick start (local)

Requirements: Node 20+, Python 3.11+, and MongoDB (local replica set, Atlas, or Docker).

```bash
npm install                                   # all JS workspaces
pip install -r optimizer/requirements.txt
cp server/.env.example server/.env            # edit MONGODB_URI etc.

npm run dev:optimizer                         # terminal 1 → http://localhost:8001
npm run seed -- --reset                       # loads Fall-26 data (development only!)
npm run dev:server                            # terminal 2 → http://localhost:4000
npm run dev:client                            # terminal 3 → http://localhost:5173
```

Or everything in Docker: `docker compose up --build` → http://localhost:4000, then
`docker compose exec web node server/dist/seed/seed.js` to load the sample data.

### Accounts created by the seed

| Account | Email | Password |
|---|---|---|
| Program Coordinator (setup) | `coordinator@cse.baiust.local` | `SEED_ADMIN_PASSWORD` (default `ChangeMe!2026`) |
| Each faculty member | `<name>@cse.baiust.local`, e.g. `md.imran.hossain.emu@cse.baiust.local` | `SEED_FACULTY_PASSWORD` (default `Faculty!2026`) |

Faculty with the PC position get the coordinator role. Everyone must change their password
at first sign-in. On a fresh production database (no seed) only the coordinator account is created.

## Main workflow

1. **Excel import** — upload the workbook, confirm sheet types and column mapping, review row-level
   errors and proposed create/update/skip actions, commit (transactional).
2. **Course distribution** — assign primary and second teachers (workload-aware suggestions),
   approve staffing exceptions when the institution allows them.
3. **Sections & groups** — confirm enrollment; propose lab groups from the target/maximum size.
4. **Settings** — confirm the workload-credit policy, working days, hours, breaks, solver weights.
5. **Routine builder** — create a draft, run the pre-solve check, generate (new / regenerate
   semesters / repair / optimize / keep manual placements), resolve conflicts by drag-and-drop or
   suggested slots, lock sessions, compare with the published version.
6. **Review → approve → publish** — publication creates an immutable numbered version and notifies
   affected faculty. Exports: PDF, Excel, per-faculty calendar (.ics).

## Tests

```bash
npm test                              # shared rules + server integration (needs DB + optimizer)
cd optimizer && python -m pytest -q   # solver tests
npm run test:e2e                      # Playwright against a running, seeded server
```

See `docs/TESTING.md` for how each of the 20 acceptance criteria is covered and the expected outputs.

## Documentation

- `docs/ARCHITECTURE.md` — data model, credit vs contact-hour rules, cohort model, solver formulation
- `docs/API.md` — REST endpoints and permissions
- `docs/DEPLOYMENT.md` — MongoDB Atlas + Render step by step
- `docs/BACKUP.md` — backup and recovery
- `docs/TROUBLESHOOTING.md`
- `docs/templates/course-distribution-template.xlsx` — blank import template
