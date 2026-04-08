---
name: create-permanent-note
description: Create a permanent note in Obsidian Vault with specified content and tags
---

# Create Permanent Note

You are creating a permanent note with the following arguments: $ARGUMENTS

Use tools: Grep, Read, Write, Task, mcp__mcp-obsidian__obsidian_complex_search, mcp__mcp-obsidian__obsidian_get_file_contents, mcp__mcp-obsidian__obsidian_batch_get_file_contents, mcp__mcp-obsidian__obsidian_put_content, mcp__time__get_current_time

## 1. Parse Arguments
Extract the --content and --tags parameters from the arguments.

## 2. Learn from Existing Notes
Use the Obsidian MCP to search for existing files that have both the PERMANENT tag AND any of the tags provided in --tags parameter. Use `mcp__mcp-obsidian__obsidian_complex_search` to find relevant files, then use `mcp__mcp-obsidian__obsidian_batch_get_file_contents` to read these files to understand:
- Writing style and structure
- YAML frontmatter format
- Content organization patterns
- Tag usage conventions
- Title generation patterns

## 3. Generate Note Components
- Use `mcp__time__get_current_time` to get the current time
- Create a unique ID using timestamp format: YYYYMMDDHHmm
- Generate current datetime for created field: YYYY-MM-DD HH:mm
- Create an appropriate title based on the content
- Combine provided tags with required tags: PERMANENT, WRITTEN_BY_AI, and date tag (YYYY/MM/DD)

## 4. Create the Note
Use `mcp__mcp-obsidian__obsidian_put_content` to write the permanent note file in the Output/ directory with:
- Proper YAML frontmatter following learned conventions
- Content formatted according to observed patterns
- Appropriate file naming convention

Make sure to follow the exact style and conventions learned from existing permanent notes with similar tags.
