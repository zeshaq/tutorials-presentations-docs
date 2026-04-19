# 6. Ambient Mode Patterns

This article explains how the gateway architecture changes if you use OpenShift Service Mesh 3 ambient mode.

## The key difference

The north-south architecture may stay mostly the same, but the in-cluster data plane changes.

In classic mode:

- ingress goes to sidecar-based mesh services

In ambient mode:

- ingress goes into the ambient secure overlay
- `ztunnel` handles L4 secure transport
- `waypoint` handles L7 features where needed

## Recommended ambient pattern

```mermaid
flowchart LR
    C["Client"] --> F5["F5"]
    F5 --> W["WSO2"]
    W --> G["Gateway API ingress"]
    G --> Z["Ambient mesh"]
    Z --> SVC["Services"]
```

## In-cluster ambient view

```mermaid
flowchart TB
    G["Gateway API ingress"] --> Z1["ztunnel node A"]
    Z1 --> Z2["ztunnel node B"]
    Z2 --> WP["Waypoint optional"]
    WP --> APP["Service"]
```

## Why this stays clean

The responsibility split does not need to change:

- `F5` still owns edge posture
- `WSO2` still owns API policy
- `Gateway API ingress` still owns cluster entry
- `Ambient mesh` still owns service security

## Ambient caution

Do not redesign the whole edge just because the mesh went ambient.

Ambient mode changes:

- internal traffic path
- mesh enforcement points
- some ingress configuration guidance

It does not automatically change:

- enterprise edge ownership
- API governance ownership
- DNS ownership

## Good way to explain it

```mermaid
flowchart LR
    EXT["Outside world"] --> F5["F5"]
    F5 --> WSO2["WSO2"]
    WSO2 --> GW["Gateway API ingress"]
    GW --> ZT["ztunnel secure overlay"]
    ZT --> WP["waypoint if L7 needed"]
    WP --> APP["services"]
```
