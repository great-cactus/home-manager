-- notmuch.nvim configuration.
--
-- Attachments: PDF/images open in evince (Linux GUI via WSLg); everything
-- else opens in the default Windows app.  On WSL the attachment cache lives
-- on the Windows side so both evince and Windows apps can read it.

local is_wsl = vim.fn.isdirectory("/mnt/c") == 1
local win_home = "/mnt/c/Users/" .. (vim.env.USER or "")

local function ext(att)
  return (att.part and att.part.ext) or ""
end

local function content_type(att)
  return (att.part and att.part.content_type) or ""
end

local function is_pdf_or_image(att)
  return content_type(att) == "application/pdf"
    or ext(att) == "pdf"
    or content_type(att):match("^image/") ~= nil
end

-- Open an attachment with the default Windows application.
local function windows_open(att)
  local winpath = vim.fn.system({ "wslpath", "-w", att.path })
  if vim.v.shell_error ~= 0 then
    return nil, "wslpath failed: " .. winpath
  end
  -- `start` treats the first quoted argument as a window title: pass "" first.
  -- cwd must be a Windows-accessible path or cmd.exe warns about UNC paths.
  vim.system(
    { "/mnt/c/Windows/System32/cmd.exe", "/d", "/s", "/c", "start", "", vim.trim(winpath) },
    { detach = true, cwd = "/mnt/c" }
  )
  return true
end

local open_rules = { prepend = {}, replace = {} }

if vim.fn.executable("evince") == 1 then
  table.insert(open_rules.prepend, {
    name = "evince",
    match = is_pdf_or_image,
    command = { "evince", "$path" },
    detach = true,
    fallback = "evince failed to open attachment",
  })
end

if is_wsl then
  open_rules.replace.system = {
    name = "system",
    match = "*",
    handler = windows_open,
    fallback = "Could not open attachment with Windows",
  }
end

require("notmuch").setup({
  maildir_sync_cmd = "mbsync -a",
  render_html_body = true,
  thread_auto_expand = "first",
  send = { send_mode = "terminal" },
  sync = { sync_mode = "terminal" },
  drafts = { delete_sent = true },
  queries = {
    { name = "未読 inbox", query = "tag:inbox and tag:unread" },
    { name = "今週", query = "date:7d.." },
    { name = "自分宛 直接", query = "to:akira.tsunoda.e7@tohoku.ac.jp and tag:inbox" },
  },
  attach = {
    incoming = {
      cache_dir = is_wsl and (win_home .. "/.cache/notmuch-attachments") or nil,
      open = { rules = open_rules },
    },
  },
})
