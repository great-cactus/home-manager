#!/usr/bin/env bash
# Run the tests, each file in its own headless Neovim.
#   *_spec.lua  unit tests, `nvim --clean` with the repo's Lua modules
#   *_int.lua   integration tests against the installed configuration
#   tests/run.sh [file-name-substring]
set -u
cd "$(dirname "$0")"
status=0
for spec in *_spec.lua *_int.lua; do
  case "$spec" in *"${1:-}"*) ;; *) continue ;; esac
  case "$spec" in
    *_int.lua) flags=(); installed=1 ;;
    *) flags=(--clean); installed=0 ;;
  esac
  echo "== $spec"
  # a spec that fails to load must not leave Neovim waiting
  load="lua local ok, err = pcall(dofile, '$spec') if not ok then io.stdout:write('\nFAIL load $spec\n  ' .. tostring(err) .. '\n') vim.cmd('cquit 2') end"
  TEST_INSTALLED=$installed timeout 300 nvim "${flags[@]}" --headless -c "$load" 2>&1 | tr '\r' '\n' |
    grep -E '^(PASS|FAIL|SKIP|  |[0-9]+ passed|E[0-9]+|Error|Lua callback|.*attempt to )'
  [ "${PIPESTATUS[0]}" -eq 0 ] || status=1
done
exit $status
