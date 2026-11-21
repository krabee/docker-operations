# docker-operations — a safe-by-default Docker skill for non-specialists

An agent skill (plain Markdown) that teaches an AI assistant — or a human — how to operate any
**Docker / docker-compose** host **without breaking production**.

Written for **project managers and operators who are not IT specialists**: it separates
*read-only* commands from *state-changing* ones and from *never-do-this-alone* ones, and it forces a
report with before/after evidence and a rollback line on every change.

> เนื้อหาเป็นภาษาไทย (คำสั่งเป็นภาษาอังกฤษ) — English translation welcome as a PR.

## What's inside

| Section | Why it exists |
|---|---|
| Golden rules (7) | read before write · no baseline = no change · never `compose down` on data stacks |
| Risk levels 🟢🟡🔴 | green = run freely, yellow = run + report, red = approval + backup first |
| Workflow (5 steps) | baseline → plan/diff → approve → apply one service → read-back + post-diff |
| Command menu | copy-paste status / logs / disk / exposure checks |
| 6 recipes | restart, update one service, DB backup, volume backup, port check, safe image removal |
| Troubleshooting | won't start · restart loop · 502 · disk full · exec not found |
| 14 real pitfalls | compose recreate scope, volume↔project name, `docker` group ≈ root, iptables rule loss on reboot, host-vs-container port, digest pinning |
| Report template | forces evidence + rollback into every change note |
| Escalation | what a PM may do alone vs. must hand to IT |
| Extension contract | how to add a per-app "spoke" skill without leaking host data into the shared file |

## Install

```bash
# Hermes Agent
cp -r docker-operations ~/.hermes/skills/devops/

# Claude Code / other agents that read folders of Markdown skills
cp -r docker-operations ~/.claude/skills/
```

The skill is self-contained: `SKILL.md` only. No scripts, no network calls, no dependencies.

## Safety

- Contains **no credentials, no IPs, no hostnames, no usernames, no company data**. Verified with
  `scripts/scan-secrets.sh` (run it before every push; it is the pre-push guard).
- Every 🔴 command is documented with *why* it is dangerous and what to back up first.
- Not a replacement for a change-management process — it is the checklist *inside* one.

## Contributing

Add pitfalls you actually hit, not theory. One rule per line, imperative, with the reason.
Keep per-site facts (IPs, container names, paths) out of `SKILL.md` — that is what spoke skills are for.

## License

MIT — see `LICENSE`.
