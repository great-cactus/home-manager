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
    # Rules from Obsidian Vault
    ".claude/rules/obsidian-communication.md".source     = ./rules/obsidian-communication.md;
    ".claude/rules/obsidian-gtd.md".source               = ./rules/obsidian-gtd.md;
    ".claude/rules/obsidian-tags.md".source              = ./rules/obsidian-tags.md;
    ".claude/rules/obsidian-zettelkasten.md".source      = ./rules/obsidian-zettelkasten.md;

    # Skills (new format only)
    ".claude/skills/coding-standards/SKILL.md".source                  = ./skills/coding-standards/SKILL.md;
    ".claude/skills/smart-commit/SKILL.md".source                      = ./skills/smart-commit/SKILL.md;
    ".claude/skills/obsidian-create-permanent-note/SKILL.md".source    = ./skills/obsidian-create-permanent-note/SKILL.md;

    # Scientific writing review skills
    ".claude/skills/review-clarity/SKILL.md".source     = ./skills/review-clarity/SKILL.md;
    ".claude/skills/review-coherence/SKILL.md".source   = ./skills/review-coherence/SKILL.md;
    ".claude/skills/review-correctness/SKILL.md".source = ./skills/review-correctness/SKILL.md;
    ".claude/skills/review-impact/SKILL.md".source      = ./skills/review-impact/SKILL.md;
  };
}
