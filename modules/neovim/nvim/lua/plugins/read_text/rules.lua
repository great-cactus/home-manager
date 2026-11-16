-- Reading rules: turn LaTeX source into text worth reading aloud.
-- Port of read-text.vim's parser and its latex preset, applied in order:
--   comments % to the end of the line (not \%)
--   ranges   environments removed with their content (nesting aware)
--   commands \cmd[opt]{arg}... kept/dropped per argument, with prefix
--   simple   markup removed (\begin{..}, $, \\, spacing, ...)
--   replace  symbols and abbreviations spelled out
--   cleanup  spaces collapsed, lines trimmed, blank lines dropped
local M = {}

M.file_patterns = { '%.tex$', '%.ltx$', '%.sty$', '%.cls$' }

local ranges = {}
for _, env in ipairs({ 'comment', 'lstlisting', 'verbatim', 'minted', 'figure', 'table' }) do
  ranges[#ranges + 1] = { '\\begin{' .. env .. '}', '\\end{' .. env .. '}' }
end

-- name = { argument count, read the arguments?, optional [..] arg, prefix }
local function cmd(n, mask, opt, prefix)
  return { n = n, mask = mask, opt = opt, prefix = prefix }
end
local KEEP, DROP = { true }, { false }
local commands = {
  section = cmd(1, KEEP, true),
  subsection = cmd(1, KEEP, true),
  subsubsection = cmd(1, KEEP, true),
  chapter = cmd(1, KEEP, true),
  paragraph = cmd(1, KEEP, true),
  subparagraph = cmd(1, KEEP, true),
  textbf = cmd(1, KEEP),
  textit = cmd(1, KEEP),
  textsl = cmd(1, KEEP),
  textsc = cmd(1, KEEP),
  textrm = cmd(1, KEEP),
  textsf = cmd(1, KEEP),
  texttt = cmd(1, KEEP),
  emph = cmd(1, KEEP),
  underline = cmd(1, KEEP),
  footnote = cmd(1, KEEP, false, 'footnote, '),
  marginpar = cmd(1, KEEP, false, 'margin note, '),
  item = cmd(0, {}, true),
  title = cmd(1, KEEP),
  author = cmd(1, KEEP),
  date = cmd(1, KEEP),
  label = cmd(1, DROP),
  ref = cmd(1, DROP),
  eqref = cmd(1, DROP),
  pageref = cmd(1, DROP),
  cite = cmd(1, DROP, true),
  citet = cmd(1, DROP, true),
  citep = cmd(1, DROP, true),
  citeauthor = cmd(1, DROP, true),
  citeyear = cmd(1, DROP, true),
  url = cmd(1, DROP),
  input = cmd(1, DROP),
  include = cmd(1, DROP),
  includegraphics = cmd(1, DROP, true),
  bibliography = cmd(1, DROP),
  bibliographystyle = cmd(1, DROP),
  usepackage = cmd(1, DROP, true),
  documentclass = cmd(1, DROP, true),
  newcommand = cmd(2, { false, false }, true),
  renewcommand = cmd(2, { false, false }, true),
  setlength = cmd(2, { false, false }),
  setcounter = cmd(2, { false, false }),
  href = cmd(2, { false, true }),
  ruby = cmd(2, { true, false }),
  ce = cmd(1, KEEP),
}

-- Plain replacements in order. A "\name" only matches the whole command
-- name, so \sin does not eat \sinh and \in does not eat \int or \inf.
local replacements = {
  { '\\alpha', 'alpha' }, { '\\beta', 'beta' }, { '\\gamma', 'gamma' }, { '\\delta', 'delta' },
  { '\\epsilon', 'epsilon' }, { '\\varepsilon', 'epsilon' }, { '\\zeta', 'zeta' }, { '\\eta', 'eta' },
  { '\\theta', 'theta' }, { '\\vartheta', 'theta' }, { '\\iota', 'iota' }, { '\\kappa', 'kappa' },
  { '\\lambda', 'lambda' }, { '\\mu', 'mu' }, { '\\nu', 'nu' }, { '\\xi', 'xi' }, { '\\pi', 'pi' },
  { '\\varpi', 'pi' }, { '\\rho', 'rho' }, { '\\varrho', 'rho' }, { '\\sigma', 'sigma' },
  { '\\varsigma', 'sigma' }, { '\\tau', 'tau' }, { '\\upsilon', 'upsilon' }, { '\\phi', 'phi' },
  { '\\varphi', 'phi' }, { '\\chi', 'chi' }, { '\\psi', 'psi' }, { '\\omega', 'omega' },
  { '\\Gamma', 'Gamma' }, { '\\Delta', 'Delta' }, { '\\Theta', 'Theta' }, { '\\Lambda', 'Lambda' },
  { '\\Xi', 'Xi' }, { '\\Pi', 'Pi' }, { '\\Sigma', 'Sigma' }, { '\\Upsilon', 'Upsilon' },
  { '\\Phi', 'Phi' }, { '\\Psi', 'Psi' }, { '\\Omega', 'Omega' },
  { '\\neq', 'not equal to' }, { '\\approx', 'approximately equal to' },
  { '\\leq', 'less than or equal to' }, { '\\geq', 'greater than or equal to' },
  { '\\times', 'times' }, { '\\div', 'divided by' }, { '\\pm', 'plus or minus' },
  { '\\mp', 'minus or plus' }, { '\\infty', 'infinity' }, { '\\partial', 'partial' },
  { '\\nabla', 'nabla' }, { '\\sum', 'sum' }, { '\\prod', 'product' }, { '\\int', 'integral' },
  { '\\oint', 'contour integral' }, { '\\rightarrow', 'right arrow' }, { '\\leftarrow', 'left arrow' },
  { '\\Rightarrow', 'implies' }, { '\\Leftarrow', 'implied by' },
  { '\\Leftrightarrow', 'if and only if' }, { '\\forall', 'for all' }, { '\\exists', 'there exists' },
  { '\\in', 'in' }, { '\\notin', 'not in' }, { '\\subset', 'subset of' },
  { '\\supset', 'superset of' }, { '\\subseteq', 'subset or equal to' },
  { '\\supseteq', 'superset or equal to' }, { '\\cup', 'union' }, { '\\cap', 'intersection' },
  { '\\emptyset', 'empty set' }, { '\\cdot', 'dot' }, { '\\equiv', 'equivalent to' },
  { '\\propto', 'proportional to' }, { '\\perp', 'perpendicular to' },
  { '\\parallel', 'parallel to' }, { '\\ldots', '...' }, { '\\cdots', '...' }, { '\\dots', '...' },
  { '\\&', 'and' }, { '\\%', 'percent' }, { '\\#', 'hash' }, { '\\_', 'underscore' },
  { '\\{', '{' }, { '\\}', '}' }, { '\\textbackslash', 'backslash' }, { '~', ' ' },
  { 'e.g.', 'eg' }, { 'i.e.', 'ie' }, { 'etc.', 'etc' }, { 'et al.', 'et al' }, { 'cf.', 'cf' },
  { 'viz.', 'viz' }, { 'vs.', 'vs' }, { 'Fig.', 'Fig' }, { 'Eq.', 'Eq' }, { 'Ref.', 'Ref' },
  { 'Tab.', 'Tab' },
  { '\\sin', 'sine' }, { '\\cos', 'cosine' }, { '\\tan', 'tangent' }, { '\\cot', 'cotangent' },
  { '\\sec', 'secant' }, { '\\csc', 'cosecant' }, { '\\arcsin', 'arc sine' },
  { '\\arccos', 'arc cosine' }, { '\\arctan', 'arc tangent' }, { '\\sinh', 'hyperbolic sine' },
  { '\\cosh', 'hyperbolic cosine' }, { '\\tanh', 'hyperbolic tangent' }, { '\\log', 'log' },
  { '\\ln', 'natural log' }, { '\\exp', 'exp' }, { '\\lim', 'limit' }, { '\\max', 'max' },
  { '\\min', 'min' }, { '\\sup', 'supremum' }, { '\\inf', 'infimum' }, { '\\det', 'determinant' },
  { '\\dim', 'dimension' }, { '\\ker', 'kernel' }, { '\\arg', 'argument' }, { '\\deg', 'degree' },
  { '\\gcd', 'greatest common divisor' }, { '\\lcm', 'least common multiple' },
  { '\\le', 'less than or equal to' }, { '\\ge', 'greater than or equal to' },
  { '\\ne', 'not equal to' }, { '\\ll', 'much less than' }, { '\\gg', 'much greater than' },
  { '\\sim', 'similar to' }, { '\\simeq', 'similar or equal to' }, { '\\cong', 'congruent to' },
  { '\\to', 'to' }, { '\\mapsto', 'maps to' }, { '\\implies', 'implies' },
  { '\\iff', 'if and only if' }, { '\\land', 'and' }, { '\\lor', 'or' }, { '\\neg', 'not' },
  { '\\wedge', 'wedge' }, { '\\vee', 'vee' }, { '\\otimes', 'tensor product' },
  { '\\oplus', 'direct sum' }, { '\\circ', 'composition' }, { '\\dagger', 'dagger' },
}

-- Units as whole words (\b in the original regexes)
local units = {
  { 'nm', 'nanometer' }, { 'μm', 'micrometer' }, { 'um', 'micrometer' }, { 'mm', 'millimeter' },
  { 'cm', 'centimeter' }, { 'km', 'kilometer' }, { 'mg', 'milligram' }, { 'kg', 'kilogram' },
  { 'ns', 'nanosecond' }, { 'ms', 'millisecond' }, { 'kHz', 'kilohertz' }, { 'MHz', 'megahertz' },
  { 'GHz', 'gigahertz' }, { 'eV', 'electron volt' }, { 'keV', 'kilo electron volt' },
  { 'MeV', 'mega electron volt' }, { 'Pa', 'pascal' }, { 'kPa', 'kilopascal' }, { 'MPa', 'megapascal' },
}

local function is_word_byte(b)
  return b and (b:match('[%w_]') ~= nil)
end

--- Replace `from` everywhere; `whole_name` requires no letter after it,
--- `whole_word` requires word boundaries on both sides.
local function replace_plain(text, from, to, whole_name, whole_word)
  local out, pos = {}, 1
  while true do
    local s, e = text:find(from, pos, true)
    if not s then
      break
    end
    local after = text:sub(e + 1, e + 1)
    local before = s > 1 and text:sub(s - 1, s - 1) or nil
    local ok = true
    if whole_name and after:match('%a') then
      ok = false
    end
    if whole_word and (is_word_byte(before) or is_word_byte(after)) then
      ok = false
    end
    out[#out + 1] = text:sub(pos, s - 1)
    out[#out + 1] = ok and to or from
    pos = e + 1
  end
  out[#out + 1] = text:sub(pos)
  return table.concat(out)
end

-- >>> ranges
local function range_end(text, open, close, from)
  local depth, pos = 1, from
  while depth > 0 do
    local next_open = text:find(open, pos, true)
    local next_close = text:find(close, pos, true)
    if not next_close then
      return #text + 1
    end
    if next_open and next_open < next_close then
      depth = depth + 1
      pos = next_open + #open
    else
      depth = depth - 1
      pos = next_close + #close
    end
  end
  return pos
end

local function remove_range(text, open, close)
  local out, pos = {}, 1
  while true do
    local s = text:find(open, pos, true)
    if not s then
      out[#out + 1] = text:sub(pos)
      break
    end
    out[#out + 1] = text:sub(pos, s - 1)
    pos = range_end(text, open, close, s + #open)
  end
  return table.concat(out)
end
-- <<< ranges

-- >>> commands
local function skip_space(text, i)
  return text:find('[^%s]', i) or #text + 1
end

--- Content of the group opened at i ("{" or "["); nil when unbalanced.
local function group(text, i, open, close)
  if text:sub(i, i) ~= open then
    return nil
  end
  local depth, j = 1, i + 1
  while j <= #text do
    local c = text:sub(j, j)
    if c == '\\' then
      j = j + 2
    else
      if c == open then
        depth = depth + 1
      elseif c == close then
        depth = depth - 1
        if depth == 0 then
          return text:sub(i + 1, j - 1), j + 1
        end
      end
      j = j + 1
    end
  end
  return nil
end

local apply_commands

local function parse_command(text, i)
  local name = text:match('^%a+', i + 1)
  local rule = name and commands[name]
  if not rule then
    return nil
  end
  local j = i + 1 + #name
  -- starred form (\section*{..})
  if text:sub(j, j) == '*' then
    j = j + 1
  end
  j = skip_space(text, j)
  local parts = {}
  if rule.opt and text:sub(j, j) == '[' then
    local _, after = group(text, j, '[', ']')
    if after then
      j = skip_space(text, after)
    end
  end
  for k = 1, rule.n do
    j = skip_space(text, j)
    local content, after = group(text, j, '{', '}')
    if not content then
      break
    end
    if rule.mask[k] then
      parts[#parts + 1] = apply_commands(content)
    end
    j = after
  end
  return (rule.prefix or '') .. table.concat(parts), j
end

apply_commands = function(text)
  local out, i = {}, 1
  while i <= #text do
    local s = text:find('\\', i, true)
    if not s then
      out[#out + 1] = text:sub(i)
      break
    end
    out[#out + 1] = text:sub(i, s - 1)
    local replaced, after = parse_command(text, s)
    if replaced then
      out[#out + 1] = replaced
      i = after
    else
      out[#out + 1] = '\\'
      i = s + 1
    end
  end
  return table.concat(out)
end
-- <<< commands

-- >>> simple
local function remove_comments(text)
  local lines = vim.split(text, '\n', { plain = true })
  for n, line in ipairs(lines) do
    local i = 1
    while true do
      local s = line:find('%', i, true)
      if not s then
        break
      end
      if s == 1 or line:sub(s - 1, s - 1) ~= '\\' then
        lines[n] = line:sub(1, s - 1)
        break
      end
      i = s + 1
    end
  end
  return table.concat(lines, '\n')
end

local simple = {
  function(t)
    t = t:gsub('\\begin{[^}]+}%[[^%]]*%]', ''):gsub('\\end{[^}]+}%[[^%]]*%]', '')
    return (t:gsub('\\begin{[^}]+}', ''):gsub('\\end{[^}]+}', ''))
  end,
  function(t)
    return (t:gsub('%$+', ''))
  end,
  -- line breaks (\\[2pt]) before the math delimiters, which would eat
  -- their second backslash
  function(t)
    return (t:gsub('\\\\%[[^%]]*%]', ''):gsub('\\\\', ''))
  end,
  function(t)
    return (t:gsub('\\[%[%]%(%)]', ''))
  end,
  function(t)
    for _, name in ipairs({ 'hspace', 'vspace', 'hfill', 'vfill', 'quad', 'qquad' }) do
      t = t:gsub('\\' .. name .. '%*?{[^}]*}', ''):gsub('\\' .. name .. '%*?', '')
    end
    return t
  end,
  function(t)
    return (t:gsub('\\[,;!]', ''):gsub('\\ ', ''))
  end,
}
-- <<< simple

local function cleanup(text)
  text = text:gsub('[ \t]+', ' ')
  local lines = {}
  for _, line in ipairs(vim.split(text, '\n', { plain = true })) do
    line = vim.trim(line)
    if line ~= '' then
      lines[#lines + 1] = line
    end
  end
  return table.concat(lines, '\n')
end

function M.parse(text)
  -- comments first: a commented-out \begin{figure} would otherwise hide
  -- the rest of the document
  text = remove_comments(text)
  for _, r in ipairs(ranges) do
    text = remove_range(text, r[1], r[2])
  end
  text = apply_commands(text)
  for _, f in ipairs(simple) do
    text = f(text)
  end
  for _, r in ipairs(replacements) do
    text = replace_plain(text, r[1], r[2], r[1]:match('^\\%a') ~= nil, false)
  end
  for _, u in ipairs(units) do
    text = replace_plain(text, u[1], u[2], false, true)
  end
  return cleanup(text)
end

--- Rules apply to LaTeX files only.
function M.applies_to(filename)
  for _, pat in ipairs(M.file_patterns) do
    if filename:lower():match(pat) then
      return true
    end
  end
  return false
end

return M
