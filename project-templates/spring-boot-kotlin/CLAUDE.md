# CLAUDE.md — Spring Boot + Kotlin (Hexagonal Architecture)

This file provides deterministic generation rules for Claude Code. Every constraint is derived from the working codebase. When generating code, follow every rule in the relevant section exactly. Code reviews succeed when there is nothing to discuss — the diff matches what this file mandates.

---

## Commands

```bash
./mvnw clean install                    # Build
./mvnw test                             # Run all tests
./mvnw test -Dtest=ClassName            # Run single test class
./mvnw spring-boot:run                  # Run application
```

---

## Package structure

Root package: `com.{company}.{module}` (e.g., `com.company.organization`).

| Layer | Package | What lives here |
|---|---|---|
| Root | `com.company.organization` | Application entry point, `@Configuration` composition root |
| Application | `com.company.organization.application` | `ApplicationService` implementations |
| Domain | `com.company.organization.domain` | Entities, domain exceptions |
| Ports | `com.company.organization.domain.port` | `Port` and `UseCase` interfaces |
| Infrastructure | `com.company.organization.infrastructure` | JPA entities, CRUD repos, adapters |
| REST | `com.company.organization.rest` | Controllers, `Representation.kt`, `GlobalExceptionHandler` |

**Naming rules — no exceptions:**

| What | Suffix | Example |
|---|---|---|
| Domain entity | none | `Employee`, `Organization` |
| Domain exception | `Exception` | `IllegalOrganizationException`, `EmployeeNotFoundException` |
| Output port | `Port` | `OrganizationRepositoryPort` |
| Input port | `UseCase` | `OrganizationUseCase` |
| JPA entity | `JpaEntity` | `EmployeeJpaEntity` |
| Spring Data repo | `CrudRepository` | `EmployeeCrudRepository` |
| Port adapter | `Adapter` (not `Impl`) | `OrganizationRepositoryAdapter` |
| Application service | `ApplicationService` | `OrganizationApplicationService` |
| REST controller | `Controller` | `OrganizationController` |
| Exception handler | `ExceptionHandler` | `GlobalExceptionHandler` |
| Config class | `Config` | `OrganizationConfig` |

---

## Dependency rule

```
rest/ ──► domain/port/ ◄── domain/
               ▲
          infrastructure/
               ▲
          application/
```

- Domain imports nothing outside `com.company.organization.domain`. No Spring, no JPA, no `application`, `infrastructure`, or `rest` imports — ever.
- `domain/port/` interfaces return and accept only domain types and primitives.
- Infrastructure imports domain and Spring/JPA. Never imports `rest`.
- REST imports `domain/port/` interfaces only. Never imports `domain` implementations directly or `infrastructure`.
- `OrganizationConfig` (root) is the only place that sees both sides of the ports: it wires the implementation to the interface.

Violation of this rule in any generated file is a blocking error.

---

## Domain layer

### Entity class rules

```kotlin
class Employee(
    val id: Long?,
    val name: String,
    var manager: Employee?,
    val managed: MutableList<Employee> = mutableListOf()
) {
    fun isRoot() = manager == null

    fun addManaged(employee: Employee) {
        managed.add(employee)
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is Employee) return false
        return name == other.name          // equality by business key, not id
    }

    override fun hashCode() = name.hashCode()

    override fun toString() = "Employee(id=$id, name=$name)"
}
```

- **Never use `data class`** for domain entities. Use `class` with manual `equals`/`hashCode` on the business key (not `id`).
- `id: Long?` is nullable; entities not yet persisted have `null` id.
- Mutable state (`var`, `MutableList`) is allowed when the domain actively mutates it.
- No framework annotations anywhere in `domain/` or `domain/port/`.
- Include `toString()` with `id` and name; exclude collection fields to avoid infinite recursion.

### Aggregate root rules

```kotlin
class Organization private constructor(
    private val _employees: MutableList<Employee>
) {
    val allEmployees: List<Employee> get() = _employees

    companion object {
        fun empty(): Organization = Organization(mutableListOf())
        fun reconstitute(employees: List<Employee>): Organization = Organization(employees.toMutableList())
    }
}
```

- **Private constructor** + companion object factory methods. No public constructor on aggregate roots.
- Factory methods: `empty()` for a new aggregate, `reconstitute(list)` for loading from persistence.
- Private backing fields prefixed with underscore: `_employees`. Exposed read-only via computed property: `val allEmployees: List<Employee> get() = _employees`.
- All business invariant checks live in the aggregate root, not in the service or adapter.

### Business method rules

```kotlin
fun removeEmployee(name: String) {
    val employee = _employees.find { it.name == name }
        ?: throw EmployeeNotFoundException(name)
    if (employee.managed.isNotEmpty())
        throw IllegalOrganizationException(
            "Cannot remove '$name': has ${employee.managed.size} direct report(s). Reassign them first.")
    employee.manager?.managed?.remove(employee)
    _employees.remove(employee)
}

private fun findOrCreate(name: String): Employee {
    require(name.isNotBlank()) { "Employee name cannot be blank" }
    return _employees.firstOrNull { it.name == name }
        ?: Employee(null, name, null).also { _employees.add(it) }
}

private tailrec fun checkCyclicDep(employee: Employee, target: Employee) {
    if (employee == target) throw IllegalOrganizationException("Cyclic dependency detected for '${target.name}'")
    checkCyclicDep(employee.manager ?: return, target)
}
```

- Validate with `?: throw ExceptionType(...)` immediately after lookup. No silent nulls.
- Use `require(condition) { "message" }` for preconditions at method entry.
- Use `error("message — context")` only for internal assertion failures that should never happen.
- Use `tailrec` for recursive traversal.
- Use `.also { }` for side effects during construction (add to list while returning the new object).
- Use `.let { }` for safe-navigation with transformation on a nullable receiver.
- Public methods: no visibility modifier (Kotlin default public). Private helpers: explicit `private`.

---

## Port interfaces

```kotlin
// Output port — what infrastructure must provide
interface OrganizationRepositoryPort {
    fun load(): Organization
    fun save(organization: Organization)
    fun deleteByName(name: String)
}

// Input port — what the application exposes to REST
interface OrganizationUseCase {
    fun getRootEmployee(): Employee?
    fun getEmployee(name: String): Employee
    fun addEmployees(employeesMap: Map<String, String>)
    fun removeEmployee(name: String)
}
```

- **No annotations** on port interfaces.
- Methods return and accept domain types and primitives only. No JPA types, no Spring types, no `Optional<T>`, no `Result<T>`.
- Explicit nullability: `Employee?` when the method may return nothing; `Employee` when it always returns or throws.
- Method names match the domain action, not the HTTP verb or the SQL operation.

---

## Infrastructure layer

### JPA entity rules

```kotlin
@Entity
@Table(name = "employee")
class EmployeeJpaEntity(
    @Id @GeneratedValue var id: Long? = null,
    var name: String = "",
    @ManyToOne(cascade = [PERSIST, MERGE], optional = true)
    @JoinColumn(name = "manager")
    var manager: EmployeeJpaEntity? = null,
    @OneToMany(mappedBy = "manager")
    var managed: MutableList<EmployeeJpaEntity> = mutableListOf()
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is EmployeeJpaEntity) return false
        return name == other.name
    }

    override fun hashCode() = name.hashCode()
}
```

- **All fields are `var`** with default values. JPA needs a no-arg constructor; Kotlin's default parameter values satisfy this.
- **Never use `data class`** for JPA entities.
- No business logic methods. No `toString()`. Only `equals`/`hashCode` by business key.
- No factory methods or companion objects.
- Cascade: `[PERSIST, MERGE]` on the owning side. `mappedBy` on the inverse side.
- No domain imports inside JPA entities.

### Spring Data repository rules

```kotlin
interface EmployeeCrudRepository : CrudRepository<EmployeeJpaEntity, Long> {
    fun findByNameIs(name: String): EmployeeJpaEntity?
    fun deleteByName(name: String)
}
```

- Extend `CrudRepository<JpaEntity, IdType>`. Never `JpaRepository` unless pagination is required.
- Custom finders use Spring Data method naming: `findBy{Field}Is()`, `deleteBy{Field}()`.
- No `@Query` annotations unless method naming cannot express the query.
- Return `JpaEntity?` (nullable) for finders that may return nothing.
- No `@Repository` annotation: Spring detects it automatically.

### Adapter rules

```kotlin
@Component
class OrganizationRepositoryAdapter(
    private val employeeCrudRepository: EmployeeCrudRepository
) : OrganizationRepositoryPort {

    override fun load(): Organization {
        val allEntities = employeeCrudRepository.findAll().toList()
        if (allEntities.isEmpty()) return Organization.empty()

        val domainMap: Map<String, Employee> = allEntities.associate { entity ->
            entity.name to Employee(entity.id, entity.name, null)
        }
        allEntities.forEach { entity ->
            entity.manager?.let { managerEntity ->
                val employee = domainMap[entity.name]
                    ?: error("Employee '${entity.name}' missing from domain map — data integrity issue")
                val manager = domainMap[managerEntity.name]
                    ?: error("Manager '${managerEntity.name}' missing from domain map — data integrity issue")
                employee.manager = manager
                if (!manager.managed.contains(employee)) manager.addManaged(employee)
            }
        }
        return Organization.reconstitute(domainMap.values.toList())
    }

    override fun save(organization: Organization) {
        val existingByName: Map<String, EmployeeJpaEntity> =
            employeeCrudRepository.findAll().associateBy { it.name }

        val jpaByName: Map<String, EmployeeJpaEntity> = organization.allEmployees.associate { employee ->
            employee.name to (existingByName[employee.name] ?: EmployeeJpaEntity(name = employee.name))
        }
        organization.allEmployees.forEach { employee ->
            val jpaEntity = jpaByName[employee.name]!!
            jpaEntity.manager = employee.manager?.let { jpaByName[it.name] }
        }
        employeeCrudRepository.saveAll(jpaByName.values.toList())
    }

    override fun deleteByName(name: String) = employeeCrudRepository.deleteByName(name)
}
```

- **`@Component`**. Never `@Service` or `@Repository` on adapters.
- **`private val`** for constructor-injected dependencies.
- **Implements the output port interface**: `class Adapter(...) : OutputPort`.
- `load()` pattern: fetch all JPA entities → build a name-keyed map → reconstruct domain relationships → `Organization.reconstitute(list)`.
- `save()` pattern: load existing JPA entities by name → upsert (reuse existing or create new) → wire relationships → `saveAll()`.
- Single-expression delegation for simple operations: `override fun deleteByName(name: String) = crudRepo.deleteByName(name)`.
- Use `error()` for data integrity assumptions (should never happen in a consistent DB).
- Use `!!` only when you have just proven the key is present (e.g., after building the map yourself on the line above).
- No domain logic in the adapter — only mapping and delegation.

---

## REST layer

### Controller rules

```kotlin
@RestController
class OrganizationController(val organization: OrganizationUseCase) {

    @PostMapping("/organization", consumes = [APPLICATION_JSON_VALUE])
    fun setOrganization(@RequestBody employeesMap: Map<String, String>) =
        organization.addEmployees(employeesMap)

    @GetMapping("/organization", produces = [APPLICATION_JSON_VALUE])
    fun getOrganization(): Map<String, Any> =
        topDown(listOfNotNull(organization.getRootEmployee()))

    @GetMapping("/organization/employee/{employeeName}/management", produces = [APPLICATION_JSON_VALUE])
    fun getEmployeeManagement(@PathVariable employeeName: String): Map<String, Any> =
        upstreamHierarchy(organization.getEmployee(employeeName))

    @DeleteMapping("/organization/employee/{name}")
    fun removeEmployee(@PathVariable name: String): ResponseEntity<Void> {
        organization.removeEmployee(name)
        return ResponseEntity.ok().build()
    }
}
```

- **`@RestController`** only. No `@RequestMapping` at class level.
- Inject the **`UseCase` interface**, not the implementation. Constructor parameter is `val` (not `private val`).
- **No try/catch** in controllers. All exception mapping lives in `GlobalExceptionHandler`.
- **No DTOs.** Requests arrive as `Map<String, String>`. Responses are `Map<String, Any>` built in `Representation.kt`.
- Return types:
  - Read operations: `Map<String, Any>`
  - Commands with no response body: `Unit` (omit return type or use single-expression form)
  - Commands requiring explicit status: `ResponseEntity<Void>`
- Always specify `produces` and `consumes` content types on mappings with a body.

### Representation rules

```kotlin
// Representation.kt — top-level functions, not a class or object
fun topDown(employees: List<Employee>): Map<String, Any> =
    employees.associate { it.name to topDown(it.managed) }

fun upstreamHierarchy(employee: Employee): Map<String, Any> =
    mapOf(employee.name to (employee.manager?.let { upstreamHierarchy(it) } ?: emptyMap<String, Any>()))
```

- **Top-level functions only** — not a class, not an object, no companion.
- File name: `Representation.kt`.
- Return `Map<String, Any>` always.
- Build responses recursively. No loops.
- No framework annotations. Imports `Employee` from domain only.
- Name functions after the view shape, not the HTTP operation (`topDown`, `upstreamHierarchy`).

### Exception handler rules

```kotlin
@RestControllerAdvice
class GlobalExceptionHandler {

    @ExceptionHandler(IllegalOrganizationException::class)
    fun handleIllegalOrganization(ex: IllegalOrganizationException): ResponseEntity<Map<String, String>> =
        badRequest().body(mapOf("error" to (ex.message ?: "Bad request")))

    @ExceptionHandler(EmployeeNotFoundException::class)
    fun handleNotFound(ex: EmployeeNotFoundException): ResponseEntity<Map<String, String>> =
        ResponseEntity.status(HttpStatus.NOT_FOUND).body(mapOf("error" to (ex.message ?: "Not found")))
}
```

- **One `@ExceptionHandler` method per exception class.** Method name: `handle{ExceptionSimpleName}()`.
- Return `ResponseEntity<Map<String, String>>`. Error body is always `mapOf("error" to message)`.
- Message fallback: `ex.message ?: "fallback string"`.
- HTTP status mapping:
  - Business rule violations → `400 BAD_REQUEST` via `badRequest().body(...)`
  - Not found → `404 NOT_FOUND` via `ResponseEntity.status(HttpStatus.NOT_FOUND).body(...)`
- Add one entry here for every new domain exception. No other class catches domain exceptions.

---

## Domain exceptions

```kotlin
// Business rule violation — takes a message string
class IllegalOrganizationException(message: String) : RuntimeException(message)

// Not found — constructs the message from the identifying key
class EmployeeNotFoundException(name: String) : RuntimeException("Employee '$name' not found")
```

- Extend `RuntimeException` directly. No intermediate base exception class.
- Live in `com.company.organization.domain`. No annotations.
- Constructor: raw `message: String` for generic violations; the identifying key (e.g., `name: String`) for not-found exceptions — the message is built inside the constructor.
- Never caught inside domain, application, infrastructure, or controller. Caught only in `GlobalExceptionHandler`.

---

## Composition root

```kotlin
@Configuration
class OrganizationConfig {

    @Bean
    fun organizationUseCase(repo: OrganizationRepositoryPort): OrganizationUseCase =
        OrganizationApplicationService(repo)
}
```

- One `@Configuration` class at the root package.
- One `@Bean` method per interface that needs wiring. Method name = interface name in camelCase.
- Return type = the **interface**. Body = direct constructor call of the implementation.
- `@Component`-annotated adapters are picked up automatically; only wire non-Spring constructs here.

---

## Kotlin idioms — mandatory and forbidden

| Pattern | Mandatory | Forbidden |
|---|---|---|
| Entity type | `class` with manual `equals`/`hashCode` | `data class` for entities or JPA entities |
| Entity equality | Business key (`name`) | `id`-based or structural equality |
| JPA entity fields | All `var` with defaults | `val` fields on JPA entities |
| Aggregate construction | `companion object { fun empty(), fun reconstitute() }` + private constructor | Public constructor on aggregate roots |
| Backing fields | `private val _list`, exposed via `get() = _list` | Mutable field exposed directly as public |
| Null + throw | `?: throw ExceptionType(msg)` | Nested `if (x == null)` checks |
| Safe navigation | `?.` and `?.let { }` | `!!` except after self-built maps |
| Tail recursion | `tailrec` for recursive traversal | Iterative cycle detection |
| Side effects | `.also { }` during construction | Separate statement after return value |
| Map building | `.associate { key to value }`, `.associateBy { it.field }` | Mutable map + `put()` loop |
| Preconditions | `require(cond) { "msg" }` | Manual `if (!cond) throw` |
| String messages | `"text '$variable'"`, `"text '${obj.field}'"` | String concatenation |
| Constructor injection (controller) | `val dep: Type` | `private val` on controllers |
| Constructor injection (adapter) | `private val dep: Type` | Field injection (`@Autowired` on field) |
| Response type | `Map<String, Any>` built in `Representation.kt` | DTOs, response wrapper classes |

---

## Development workflow

This project uses the `adr-workflow` skill. Install it globally:

```bash
cp -r /path/to/ai-assist-coding/skills/adr-workflow ~/.claude/skills/
```

Invoke at the start of each task:

```
/adr-workflow <brief description>
```

The hooks in `.claude/hooks/` enforce the workflow at commit time. Every change — feature, fix, refactor, config — requires an ADR in `docs/adr/`.

Mandatory sequence per task:

1. Confirm GitHub issue number
2. Create `docs/adr/ADR-NNNN-title.md` and fill **REASON section only** before opening any source file
3. Create branch `issue-{number}-{kebab-description}`
4. Explore relevant code paths (Explore subagent)
5. Plan solution and get explicit approval (Plan subagent)
6. Write failing `IntegrationTest` first
7. Implement minimum code to make it pass
8. Complete ADR (Change + Consequences)
9. Stage ADR + source and commit
