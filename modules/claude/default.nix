{ config, pkgs, ... }:

{
  home.file = {
    # Rules
    ".claude/rules/agents.md".source            = ./rules/agents.md;
    ".claude/rules/annotation_by_LLM.md".source = ./rules/annotation_by_LLM.md;
    ".claude/rules/coding-style.md".source      = ./rules/coding-style.md;
    ".claude/rules/core-principles.md".source   = ./rules/core-principles.md;
    ".claude/rules/git-workflow.md".source      = ./rules/git-workflow.md;
    ".claude/rules/hooks.md".source             = ./rules/hooks.md;
    ".claude/rules/patterns.md".source          = ./rules/patterns.md;
    ".claude/rules/performance.md".source       = ./rules/performance.md;
    ".claude/rules/security.md".source          = ./rules/security.md;
    ".claude/rules/testing.md".source           = ./rules/testing.md;

    # Skills (new format only)
    ".claude/skills/coding-standards/SKILL.md".source = ./skills/coding-standards/SKILL.md;
    ".claude/skills/smart-commit/SKILL.md".source     = ./skills/smart-commit/SKILL.md;
  };
}
