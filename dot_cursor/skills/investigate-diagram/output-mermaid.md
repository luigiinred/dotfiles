# Output: Mermaid in Markdown

How to generate the diagram as a Mermaid code block inside a markdown file.

## Layout Rules

- **Direction**: `graph TD` for code-level dependency trees (top-down). `flowchart LR` for architecture diagrams (left-to-right).
- **Label every arrow**: Every edge MUST have a label. If you can't name the relationship, reconsider whether it belongs.
- **Quote all text**: Double-quote all node labels and edge labels.
- **Short subgraph names**: Under ~25 characters to avoid truncation in renderers.
- **Arrow budget**: 15-20 for simple diagrams, up to 25 for complex. Beyond 25, split into multiple diagrams.
- **Node ordering**: Declare nodes in flow order. Dagre lays out in declaration order — inputs first, then processing, then outputs reduces arrow crossings.
- **Edge ordering**: Group edges by direction. Define all forward edges before cross-subgraph edges. Mixing directions causes messy routing.
- **Reduce fan-out**: If one node connects to 5+, introduce an intermediate aggregator node.
- **Subgraph direction**: Override parent direction with `direction TB` or `direction LR` inside individual subgraphs.

## Code-Level Style Palette

Apply `style` directives to color nodes and subgraphs by type:

| Node type | fill | stroke | color |
|---|---|---|---|
| `graphql-query` | `#e8f5e9` | `#2e7d32` | `#1b5e20` |
| `data-hook` (root) | `#e3f2fd` | `#1565c0` | `#0d47a1` |
| `context-provider` | `#fff3e0` | `#e65100` | `#bf360c` |
| `data-hook` (leaf) | `#f3e5f5` | `#6a1b9a` | `#4a148c` |
| `composition-hook` | `#fce4ec` | `#880e4f` | `#880e4f` |
| `component` | `#f5f5f5` | `#616161` | `#212121` |
| `deprecated` | `#ffebee` | `#c62828` | `#b71c1c` |

## Code-Level Node Shapes

| Type | Mermaid shape |
|---|---|
| `graphql-query` | Parallelogram `[/"..."/]` |
| All others | Rectangle `["..."]` |
| `hoc` | Dashed border (use `:::dashed` class) |

Rich labels are supported — use `<b>` for names and `<br/><i>filename.ts</i>` for file paths.

## Edge Conventions

| Meaning | Syntax | When to use |
|---|---|---|
| Fires a GraphQL query | `-.->` (dotted) with hook name as label | Hook → query |
| Direct dependency | `-->` (solid) with consumed export as label | Hook/provider → dependency |
| Shared/cross-team | `-.->` (dashed) | Architecture: cross-boundary |

## Template: Code-Level

````mermaid
graph TD
    %% ══ Row N — {Row Label} ══
    subgraph row_n ["{Row Label}"]
        direction LR
        nodeId["<b>DisplayName</b><br/><i>filename.ts</i>"]
    end

    %% ── Styles ──
    style row_n fill:#...,stroke:#...,color:#...
    style nodeId fill:#...,stroke:#...,color:#...

    %% ── Edges ──
    source -->|label| target
    source -.->|label| target
````

## Template: Architecture-Level

````mermaid
flowchart LR
    subgraph group1 ["Group Name"]
        nd1["Service A"]
        nd2["Service B"]
    end

    subgraph group2 ["Another Group"]
        nd3["Service C"]
    end

    nd1 -->|"relationship"| nd3
    nd2 -.->|"cross-boundary"| nd3

    style nd1 fill:#e3f2fd,stroke:#1565c0
    style nd3 fill:#fff3e0,stroke:#e65100
````

## Output File Structure

Write a markdown file with these sections:

1. **Title** — "Dependency Graph: {entry point or system names}"
2. **Mermaid diagram** — the layered graph
3. **Legend** — table mapping row colors to meanings, edge styles to meanings
4. **Node inventory** — table: Name, File/Source, Type, Dependencies count
5. **Key observations** — notable findings (duplicates, circular deps, over-fetching, deprecated usage, missing connections)

## Context Nodes

Some nodes exist to show organizational context (team ownership, platform dependencies) rather than data flow. Their placement within a subgroup communicates their role — not every node needs an arrow.
