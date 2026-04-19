
graph TD
    subgraph Monitored Systems
        A[Web Application]
        B[Microservices]
        C[Database]
    end

    subgraph Observability Pipeline
        G[Data Collector / Agent<br/>e.g., OpenTelemetry]
        H[Processing & Ingestion]
        I[(Storage<br/>TSDB, Log Storage, Trace Backend)]
    end

    subgraph Telemetry Data
        D[Metrics]
        E[Logs]
        F[Traces]
    end

    subgraph Action & Analysis
        J[Visualization / Dashboards<br/>e.g., Grafana, Datadog]
        K[Alerting & Notification<br/>e.g., PagerDuty, Slack]
        L((DevOps / SRE Team))
    end

    %% Flow of data
    A -.-> G
    B -.-> G
    C -.-> G

    G --> |Extracts| D
    G --> |Extracts| E
    G --> |Extracts| F

    D --> H
    E --> H
    F --> H

    H --> I
    I --> J
    I --> K

    J --> L
    K --> L
    
    classDef default fill:#f9f9f9,stroke:#333,stroke-width:1px;
    classDef storage fill:#e1f5fe,stroke:#01579b,stroke-width:2px;
    classDef alert fill:#ffebee,stroke:#b71c1c,stroke-width:2px;
    classDef team fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px;
    
    class I storage;
    class K alert;
    class L team;