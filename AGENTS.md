<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **mobile** (898 symbols, 1623 relationships, 1 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> If any GitNexus tool warns the index is stale, run `npx gitnexus analyze` in terminal first.

## Always Do

- **MUST run impact analysis before editing any symbol.** Before modifying a function, class, or method, run `gitnexus_impact({target: "symbolName", direction: "upstream"})` and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run `gitnexus_detect_changes()` before committing** to verify your changes only affect expected symbols and execution flows.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- When exploring unfamiliar code, use `gitnexus_query({query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `gitnexus_context({name: "symbolName"})`.

## Never Do

- NEVER edit a function, class, or method without first running `gitnexus_impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER rename symbols with find-and-replace — use `gitnexus_rename` which understands the call graph.
- NEVER commit changes without running `gitnexus_detect_changes()` to check affected scope.

## Resources

| Resource | Use for |
|----------|---------|
| `gitnexus://repo/mobile/context` | Codebase overview, check index freshness |
| `gitnexus://repo/mobile/clusters` | All functional areas |
| `gitnexus://repo/mobile/processes` | All execution flows |
| `gitnexus://repo/mobile/process/{name}` | Step-by-step execution trace |

## CLI

| Task | Read this skill file |
|------|---------------------|
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->

---

# InsForge Backend — Instrucciones de integración

> Esta app Flutter usa InsForge como BaaS. Para integración Flutter usa el **Kotlin SDK** o la **REST API** — no el TypeScript SDK.

## Qué provee InsForge

- **Database**: PostgreSQL con API PostgREST
- **Authentication**: Email/password + OAuth (Google, GitHub)
- **Storage**: Subida/descarga de archivos
- **AI**: Chat completions e imagen (compatible OpenAI)
- **Functions**: Serverless functions
- **Realtime**: WebSocket pub/sub

## Antes de escribir código de integración InsForge

Usa el MCP tool `fetch-sdk-docs` para obtener la documentación actualizada:

```
fetch-sdk-docs(feature: "auth", language: "kotlin")
fetch-sdk-docs(feature: "db", language: "kotlin")
fetch-sdk-docs(feature: "storage", language: "kotlin")
```

Features disponibles: `db`, `storage`, `functions`, `auth`, `ai`, `realtime`

## Servicios ya implementados (pendientes de conectar al UI)

- `lib/core/network/insforge_client.dart` — cliente HTTP base
- `lib/core/database/database_service.dart` — operaciones de base de datos
- `lib/features/auth/services/auth_service.dart` — registro, login, logout

## Cuándo usar SDK vs MCP Tools

**SDK (desde el app Flutter):** auth, CRUD, storage, AI, serverless functions  
**MCP Tools (infraestructura):** esquema de base de datos, buckets, deploy, metadata del backend
