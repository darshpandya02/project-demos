#!/usr/bin/env bash
# Session: MediTrack test suite on PostgreSQL 17, then the concurrency control experiment.
# Run from the root of a meditrack checkout with a local PostgreSQL. The database password is
# passed through PGPASSWORD in the environment, so it never appears in the recording.
set -u
source "$(dirname "$0")/lib.sh"
PROMPT_DIR="meditrack"
clear

note "build the solution (.NET 10): Core, Infrastructure, Api, Web, tests, benchmark"
run 'dotnet build -c Release --nologo -v q'

note "unit tests: services on the real EF Core model and migrations, in-memory SQLite"
run 'dotnet test tests/MediTrack.UnitTests -c Release --no-build --nologo'

note "integration tests through WebApplicationFactory; each fixture gets its own PostgreSQL 17 database"
run 'export MEDITRACK_TEST_PG="Host=localhost;Database=postgres;Username=meditrack"'
run 'dotnet test tests/MediTrack.IntegrationTests -c Release --no-build --nologo'

note "the concurrency test: 50 simultaneous issues and transfers, 150 units asked for, 100 on hand"
run 'dotnet test tests/MediTrack.IntegrationTests -c Release --no-build --nologo --filter "FullyQualifiedName~Parallel_issues" --logger "console;verbosity=detailed" | grep -E "provider=|Passed "'

note "control experiment: the same race through the services, with and without the concurrency token"
run 'dotnet run -c Release --no-build --project bench/MediTrack.Benchmarks -- race'
