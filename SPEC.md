# jido-cartographer MVP specification

## Purpose

Prove that BEAM processes and Jido 2.x agents can index many source files concurrently and return a useful deterministic code map without an LLM.

## Acceptance criteria

1. `POST /api/index` accepts a public GitHub repository URL and an optional Git ref.
2. The service accepts only credential-free `https://github.com/<owner>/<repo>` URLs with simple owner, repository, and ref values.
3. The fetcher downloads a bounded GitHub archive without shell interpolation, rejects redirects away from approved GitHub archive hosts, and enforces archive, file-count, per-file, and request time limits.
4. Binary files and common vendor, dependency, generated, cache, and build directories are skipped.
5. Every supported source file is processed by one lightweight Jido 2.x agent process. Files are processed concurrently with a configured concurrency cap.
6. Each file result includes path, language, line count, byte count, imports or dependencies, and practical deterministic symbol definitions or exports.
7. Aggregation returns language totals, file facts, dependency edges, errors, and measured timing including discovered files, agents spawned, concurrency, fetch time, analysis time, and total time.
8. `GET /health` reports service health. `GET /api/results/:id` reports queued, running, complete, or failed status.
9. A minimal Cloudflare Worker UI submits a public repository and renders summary, files, edges, timing, and errors.
10. The Worker routes API traffic to the Elixir release in a Cloudflare Container when Containers are available. It never invents successful container results.
11. Automated tests cover URL validation, extraction, limits, concurrent aggregation, HTTP API behavior, Worker routing, and the rendered UI shell.
12. A benchmark indexes at least one substantial public repository and records the actual repository, ref, files, agents, bytes, timing, and machine or deployed environment.
13. The repository contains a clear README, a reproducible Docker image, a clean git history, a public GitHub remote, and a deployed Worker URL.

## MVP limits

- Public GitHub repositories only.
- Maximum archive download: 25 MiB compressed.
- Maximum candidate files: 2,000.
- Maximum supported source file: 512 KiB.
- Maximum expanded supported source bytes: 64 MiB.
- Maximum concurrent file agents: 256.
- Fetch timeout: 20 seconds.
- Index timeout: 60 seconds.
- Results are in memory and can disappear when a container sleeps or restarts.
- Extraction is lexical and deterministic. It is not a compiler or semantic language server.
