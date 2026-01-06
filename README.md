# nebimv3-workplacecode-migration

SQL-based migration tool for updating WorkplaceCode across Nebim V3 ERP databases with transactional safety and validation scripts.

---

## Overview

This repository provides a **controlled, repeatable, and safe SQL migration approach**
for updating `WorkplaceCode` values across **Nebim V3 ERP** environments.

The solution is designed to:
- Prevent partial updates
- Ensure master data consistency
- Provide clear validation and sign-off steps
- Support ERP change-management standards

---

## Scope

- Nebim V3 ERP databases (e.g. OLKAV3-compatible schemas)
- WorkplaceCode master data (`cdWorkplace`, `cdWorkplaceDesc`)
- Dependent transactional and reference tables
- SQL Server environments

> ⚠️ All scripts are **generic and anonymized**.  
> Replace placeholder values according to your environment.

---

## Migration Flow

The migration is intentionally split into **three clear steps**:

### 1️⃣ Generate UPDATE Statements
**File:** `sql/01_generate_updates.sql`

- Generates dynamic `UPDATE` statements for dependent tables
- Identifies where `WorkplaceCode` is used
- Prevents manual, error-prone updates

---

### 2️⃣ Apply Migration (Transactional)
**File:** `sql/02_apply_migration.sql`

- Inserts missing master data for the new `WorkplaceCode`
- Applies all updates inside `TRY / CATCH` + `TRANSACTION`
- Prevents partial or inconsistent updates
- Designed to be production-safe (with proper testing)

---

### 3️⃣ Validate Migration Results
**File:** `sql/03_validation.sql`

- Confirms new WorkplaceCode exists in master tables
- Checks remaining occurrences of old/new codes
- Produces a clear summary for migration sign-off

---

## Execution Order

Always run scripts in the following order:

1. `sql/01_generate_updates.sql`
2. `sql/02_apply_migration.sql`
3. `sql/03_validation.sql`

---

## Safety Guidelines

- ✅ Always test in **non-production** environments first
- ✅ Take a **full database backup** before production execution
- ❌ Never hard-code server names, credentials, or real company data
- ⚠️ Review generated UPDATE statements before execution

---

## Rollback Strategy

- The migration does **not automatically delete** old WorkplaceCode records
- Rollback can be performed by:
  - Reverting updates using inverse mappings
  - Restoring from backup (recommended for production)
- See `docs/rollback.md` for guidance

---

## Use Cases

- ERP organizational restructuring
- Warehouse / workplace code standardization
- Data cleanup after master data consolidation
- Controlled ERP data migration projects

---

## Disclaimer

This repository is provided as a **technical reference and migration template**.
Adapt scripts carefully based on your ERP schema, business rules, and governance policies.

