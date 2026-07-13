-- require("sshfs"):setup()

-- You can configure your bookmarks by lua language
local path_sep = package.config:sub(1, 1)

local function resolve_path(path, base)
  -- Si ya es absoluto (/ en unix, ~ para home), no tocar
  if path:sub(1, 1) == "/" or path:sub(1, 1) == "~" then
    return path
  end
  return base .. path_sep .. path
end

local function load_workspace_hops()
  local workspace_home = os.getenv("YOBY_WORKSPACE_HOME") or os.getenv("WORKSPACE_HOME")
  if not workspace_home then return {} end

  local hops_file = workspace_home .. path_sep .. ".yobydev" .. path_sep .. "yazi-hops.lua"
  local f = io.open(hops_file, "r")
  if not f then return {} end
  f:close()

  local ok, raw_hops = pcall(dofile, hops_file)
  if not ok or type(raw_hops) ~= "table" then
    return {}
  end

  local resolved = {}
  for _, hop in ipairs(raw_hops) do
    table.insert(resolved, {
      key = hop.key,
      desc = hop.desc,
      path = resolve_path(hop.path, workspace_home),
    })
  end
  return resolved
end

local bookmarks = {
	{
		key = "h", path = "~", desc = "Home"
	},
  -- ... tus hops fijos (/, t, n, ~, m, d, D, c, l+s, l+b, l+t) ...
}

for _, hop in ipairs(load_workspace_hops()) do
  table.insert(bookmarks, hop)
end

require("bunny"):setup({
  hops = bookmarks,
  desc_strategy = "path",
  ephemeral = true,
  tabs = true,
  notify = false,
  fuzzy_cmd = "fzf",
})

