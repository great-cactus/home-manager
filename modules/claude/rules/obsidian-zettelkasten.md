# Zettelkasten System Rules

## Directory Structure

- `Input/` - All input materials (no personal opinions)
- `Output/` - All Zettelkasten notes
- `Templates/` - Note creation templates

## Note Types

### 1. Fleeting Notes (走書き)
- Quick capture of ideas
- Managed in DailyNotes
- Temporary storage for raw thoughts

### 2. Literature Notes (文献ノート)
- Knowledge and insights from sources
- Must reference source material
- Tagged with `LITERATURE`
- Stored in `Output/` directory

**YAML Frontmatter:**
```yaml
---
ID: YYYYMMDDHHmm
created: YYYY-MM-DD HH:mm
title: "Literature note title"
aliases: []
tags: [ YYYY/MM/DD, LITERATURE, WRITTEN_BY_AI ]
---
```

### 3. Permanent Notes (永続ノート)
- Developed ideas from Fleeting and Literature notes
- Original thoughts and arguments
- Tagged with `PERMANENT`
- Stored in `Output/` directory

**YAML Frontmatter:**
```yaml
---
ID: YYYYMMDDHHmm
created: YYYY-MM-DD HH:mm
title: "Permanent note title"
aliases: []
tags: [ YYYY/MM/DD, PERMANENT, WRITTEN_BY_AI ]
---
```

### 4. Structure Notes (構造ノート)
- Comprehensive arguments on specific topics
- Synthesize multiple Permanent notes
- Tagged with `STRUCTURE`
- Represent final output stage

## Note Creation Rules

1. **One Topic Per Note**: Each note focuses on a single topic
2. **Proper Citations**: Use quote blocks and link to source notes
3. **Required Context**: Include necessary background knowledge
4. **Appropriate Tags**: Use existing tag namespace
5. **Linking**: Create appropriate links between related notes

## Timestamp Generation

Use `mcp__time__get_current_time` to obtain accurate timestamp for:
- ID field (format: `YYYYMMDDHHmm`)
- created field (format: `YYYY-MM-DD HH:mm`)

## Templates

- `Templates/ZK-LITERATURE.md` - Literature note creation
- `Templates/ZK-PERMANENT.md` - Permanent note creation

## Claude's Responsibilities

1. **Note Type Recognition**: Correctly identify and categorize note types
2. **Tag Management**: Apply appropriate tags from existing namespace
3. **Link Creation**: Establish meaningful connections between notes
4. **Content Validation**: Ensure notes have sufficient context and proper citations
5. **Network Growth**: Facilitate information network expansion
6. **Note Splitting**: Suggest note division when multiple topics are detected
