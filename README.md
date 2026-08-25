# lts-powertrain

Powertrain component package for the FSAE transient lap-time simulation:
the `+Powertrain` classes (`EMRAX228Powertrain`, differentials) and the
EMRAX motor maps under `data/powertrain/`, mounted into the main
repository at `src/+lts/+components/+Powertrain`.

## Ownership

| | |
|---|---|
| Department | Powertrain |
| Maintainer | *add GitHub handle* |
| Term | *e.g. 2026/27* |

## Running the tests

Requires MATLAB R2019b+ (CI pins R2026a) and the `lts-kit` submodule:

    git submodule update --init --recursive

Then in MATLAB, from the repository root: `run_tests`

The runner assembles a temporary `+lts` package sandbox in `build/`
(gitignored) — this repository's classes and `data/` maps plus kit's
`+util` — and runs `tests/`. The default EMRAX map resolves relative to
the package folder, so it works standalone and mounted alike.

## Branch model and workflow

- `staging` — where PRs from forks land. `main` — stable, release-only; it advances only via the release cascade from the main `lts` repository.
- All development is done on forks; see [CONTRIBUTING.md](CONTRIBUTING.md).

## Contract with the main repository

- The main repository constructs `EMRAX228Powertrain` from
  `cfg.powertrain` fields (`matFile` may be `''` for the default map,
  `efficiency`, optional `motorRotorInertia`, efficiency/regen knobs); SI
  units throughout.
- The EMRAX `.mat` maps live in this repository's `data/powertrain/`;
  they are loaded only through `lts.util.loadMatSafe` (plain-data
  screening).
- `tests/ConformanceTest.m` pins the `cfg.powertrain` schema
  (`validateConfig`), the `PowertrainComponent`/`DifferentialComponent`
  interfaces, and the `PowertrainState` property names feeding the
  motor/pack telemetry channels. Renaming any of them is a **contract
  change** — see "Changing the contract" on the
  [Contracts page](https://jyjh.github.io/lts/contracts/).
- Details: <https://jyjh.github.io/lts/repo-split/>
