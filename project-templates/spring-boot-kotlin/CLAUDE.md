# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Commands

```bash
./mvnw clean install                    # Build
./mvnw test                             # Run all tests
./mvnw test -Dtest=ExampleTest          # Run a single test class
./mvnw spring-boot:run                  # Run the application
```

## Architecture

This is a Spring Boot + Kotlin project following **hexagonal (ports & adapters)** architecture. The dependency rule is enforced: only infrastructure and REST depend on domain, never the reverse.

```
rest/ ──► domain/port/ ◄── domain/
               ▲
          infrastructure/
```

### Domain (`domain/`)

Framework-free. No Spring or JPA imports anywhere in this package.

- Core domain entities as pure Kotlin `data class` or plain `class`
- Domain exceptions with no HTTP knowledge
- `domain/port/` — output port interfaces (what persistence must provide) and input port interfaces (what the application exposes)

### Infrastructure (`infrastructure/`)

Owns all JPA/persistence concerns.

- JPA `@Entity` classes kept entirely separate from domain entities
- Spring Data repositories
- `@Component` adapters implementing output port interfaces, translating between JPA and domain types

### REST (`rest/`)

- `@RestController` classes depend on input port interfaces, not on domain implementations directly
- Representation functions that serialize domain objects to response shapes
- `@RestControllerAdvice` that maps domain exceptions to HTTP status codes

### Composition root

A `@Configuration` class wires domain implementations with port interfaces, keeping Spring DI out of the domain.

## Testing strategy

- `@SpringBootTest` + `@Transactional` for repository tests (hits real in-memory DB via `EntityManager`)
- Mocked repository port for domain logic tests (no Spring context)
- Mocked use case port for controller tests (no Spring context)
- `@SpringBootTest(webEnvironment = RANDOM_PORT)` for integration tests (full HTTP round-trip)

## Development Workflow

This project uses the ADR workflow skill. Install it globally:

```bash
cp -r /path/to/ai-assist-coding/skills/adr-workflow ~/.claude/skills/
```

Then invoke it at the start of each task:

```
/adr-workflow <brief description>
```

The hooks in `.claude/hooks/` enforce the workflow at commit time. See `hooks/README.md` in ai-assist-coding for details.

Every task follows this mandatory sequence — do not skip or reorder:

1. Confirm GitHub issue number
2. Create ADR and fill REASON section **before** opening any source file
3. Create branch `issue-{number}-{kebab-description}`
4. Explore relevant code paths
5. Plan solution and get explicit approval
6. Write failing acceptance test (`IntegrationTests` against real HTTP)
7. Implement minimum code to make it pass
8. Complete ADR (Change + Consequences sections)
9. Stage ADR + source and commit

Non-functional changes (CI, deps, refactors, config) require ARDs too.

## Key dependencies

<!-- Update these for your project -->
- Java 25, Kotlin 2.x, Spring Boot 4.x
- Kotlin compiler plugins: `spring`, `jpa`, `all-open`
- Jackson Kotlin module for JSON serialization of data classes
