# jido-cartographer

A measured concurrency demo built with [Jido 2.x](https://hex.pm/packages/jido), Elixir, and Cloudflare Containers.

**Live:** https://jido-cartographer.coy.workers.dev

Give it a public GitHub repository. It downloads a bounded source snapshot, starts one lightweight Jido agent in one BEAM task process for every supported file, extracts deterministic lexical facts, and folds the results into a code map. It does not use an LLM.

## What it shows

- One Jido agent and one BEAM task process per supported source file.
- Bounded `Task.async_stream/3` fan-out across BEAM schedulers.
- Deterministic language, symbol, import, and dependency extraction.
- Aggregate file, line, byte, symbol, language, edge, and timing metrics.
- An asynchronous JSON API behind a Cloudflare Worker and Container.
- A small browser UI for summary metrics, languages, dependency edges, and files.

## Architecture

```text
Browser
  │
  ▼
Cloudflare Worker ── HTML UI and request routing
  │
  ▼
Container Durable Object ── one basic container, sleep after 10 minutes
  │
  ▼
Plug API ── result store and supervised jobs
  │
  ├── bounded GitHub codeload fetch
  ├── tar metadata preflight
  └── Task.async_stream
        ├── Jido file agent 1
        ├── Jido file agent 2
        └── Jido file agent N
              │
              ▼
        deterministic aggregate
```

The Worker sends all API traffic to one named Container Durable Object. The Cloudflare configuration allows one `basic` instance. The API admits no more than two active indexes and retains at most 100 results in memory. Container sleep or restart clears results.

## Live API

```sh
base=https://jido-cartographer.coy.workers.dev

curl "$base/health"
curl "$base/api/health"

job=$(curl -sS -H 'content-type: application/json' \
  -d '{"url":"https://github.com/agentjido/jido","ref":"v2.3.3"}' \
  "$base/api/index")

id=$(printf '%s' "$job" | jq -r .id)
curl "$base/api/results/$id"
```

`POST /api/index` returns `202` and a job ID. Poll the result route until `status` is `complete` or `failed`.

## Safety bounds

Only credential-free `https://github.com/{owner}/{repository}` URLs are accepted. The service constructs the `codeload.github.com` URL itself. It never runs a repository command or interpolates input into a shell command.

| Limit | Value |
|---|---:|
| Compressed archive | 25 MiB |
| Archive entries before extraction | 10,000 |
| Supported source files | 2,000 |
| One source file | 512 KiB |
| Expanded archive bytes | 64 MiB |
| Fetch time | 20 seconds |
| Whole index | 60 seconds |
| Agent concurrency | 256 maximum |
| Active API indexes | 2 |

Binary files and these directory segments are skipped: `.git`, `.github`, `node_modules`, `deps`, `vendor`, `_build`, `build`, `dist`, `target`, `coverage`, `.next`, `.cache`, `__pycache__`, `venv`, `.venv`, `fixtures`, and `testdata`.

Supported source languages are Elixir, Erlang, TypeScript, JavaScript, Python, Ruby, Go, Rust, Java, Kotlin, Swift, C, C++, C#, and shell scripts. Extraction is lexical, not a full parser, so symbols and edges are useful approximations.

## Measured benchmark

The tracked receipt is [`benchmark-results.json`](benchmark-results.json).

On 2026-08-26, an Apple arm64 machine with 14 online schedulers indexed `agentjido/jido@v2.3.3`:

| Metric | Result |
|---|---:|
| Source files / Jido agents | 297 |
| Source bytes | 2,432,272 |
| Lines | 78,420 |
| Symbols | 2,840 |
| Dependency edges | 1,104 |
| Fetch | 1,038 ms |
| Agent analysis | 6 ms |
| Total | 1,049 ms |

A live Cloudflare Container run of the same ref produced the same facts with 297 agents, 353 ms fetch, 204 ms analysis, and 557 ms total. Timings vary with network, cold starts, and available schedulers.

Reproduce the local measurement:

```sh
mix deps.get
PORT=0 mix run scripts/benchmark.exs -- \
  https://github.com/agentjido/jido v2.3.3
```

## Development

Elixir service:

```sh
mix deps.get
mix test
mix run --no-halt
```

Worker:

```sh
cd worker
npm install
npm run check
npm test
npx wrangler deploy --dry-run
```

Container:

```sh
docker build -t jido-cartographer .
docker run --rm -p 8080:8080 jido-cartographer
```

The build compiles BEAM bytecode on the build platform and copies it into the target-platform Elixir runtime. This keeps `linux/amd64` Cloudflare image builds deterministic on arm64 development machines.

## Verification

The current proof set is:

- 16 Elixir tests for URL validation, extraction, archive limits, concurrency, aggregation, timeout, admission control, and API behavior.
- 4 Worker tests for UI content and routing.
- TypeScript strict type checking.
- Native arm64 and cross-platform `linux/amd64` container health checks.
- A successful Cloudflare Worker and Container deployment.
- A live end-to-end index of `agentjido/jido@v2.3.3` with deterministic parity against the local benchmark.

See [`SPEC.md`](SPEC.md) for the acceptance contract and [`receipts/deployment.json`](receipts/deployment.json) for the deployment and live-run receipt.

## License

MIT
