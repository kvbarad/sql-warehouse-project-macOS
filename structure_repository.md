sqp-warehouse-project-mac/
│
├── README.md             # Project overview and main instructions
├── LICENSE               # License details
├── .gitignore            # Ignored files and folders (optional)
│
├── docs/                 # Supplementary and process documentation
│   ├── SETUP_PROCESS.md
│   └── CONTRIBUTING.md
│
├── scripts/              # Bash or shell scripts for environment setup and management
│   ├── start-sql.sh
│   └── stop-sql.sh
│
├── sql/                  # All SQL scripts: DDL, DML, ETL, tests, and samples
│   ├── schema.sql
│   ├── seed.sql
│   └── etl/
│       └── sample_etl.sql
│
├── .devcontainer/        # VSCode container configuration (if used)
│   └── devcontainer.json
│
├── config/               # Any configuration files (Docker, environment variables)
│   ├── .env.example
│   └── docker-compose.yml
│
└── test/                 # Optional: unit or integration tests for scripts (if applicable)
    └── test_sample.sql
