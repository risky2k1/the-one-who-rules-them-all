# Shared Contracts (`contracts/`)

This directory is the single source of truth for cross-service API specifications, message payloads, and schemas shared across `the-one-who-rules-them-all`.

## Purpose
Because services in this architecture do not share databases or internal code directly, all inter-service communication happens over HTTP/gRPC or asynchronous queues. Defining contracts here first keeps producer and consumer services decoupled and verifiable.

## Planned Layout
```text
contracts/
├── README.md
├── openapi/          # OpenAPI 3.1 YAML specifications (CMS REST API, Go API, etc.)
├── proto/            # Protocol Buffers (.proto) definitions for internal RPCs
└── events/           # JSON Schema / AsyncAPI definitions for Redis queue payloads
```

## Guidelines
1. **Contract-First Changes**: Update or add the specification in `contracts/` before implementing breaking changes in a service submodule.
2. **Versioning**: Use explicit version prefixes or filenames (e.g., `openapi/cms.v1.yaml`) when introducing breaking changes.
3. **No Secrets**: Never include real tokens, production URLs, or credentials in example payloads.
