How to set up your environment for running tests:

1. Run `script/bootstrap`

   **Note:** on systems without Homebrew, you must ensure that MySQL 5.7, PostgreSQL 12, and MongoDB 4.x Community Edition are up and running.

2. Run `script/test_all`

   This ensures that the Active Record part of the suite is run across `sqlite3`, `mysql`, and `postgres` database adapters.
