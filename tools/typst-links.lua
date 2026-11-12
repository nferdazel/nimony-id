-- Typst output turns internal `.qmd` links into `#link("chapters/x.qmd")`, which the
-- PDF reader treats as a file attachment: clicking one does nothing. Rewrite those
-- targets to the published web page instead. HTML output is untouched.

local SITE = "https://nimony.qouver.com"

local function dirname(path)
  return path:match("^(.*)/[^/]+$") or "."
end

local function resolve(base, rel)
  local out = {}
  for segment in (base .. "/" .. rel):gmatch("[^/]+") do
    if segment == ".." then
      if #out > 0 then table.remove(out) end
    elseif segment ~= "." then
      table.insert(out, segment)
    end
  end
  return table.concat(out, "/")
end

local function project_relative(path)
  local root = quarto.project.directory
  if root and root ~= "" and path:sub(1, #root) == root then
    return (path:sub(#root + 1):gsub("^/", ""))
  end
  return (path:gsub("^%./", ""))
end

function Link(el)
  local target, fragment = el.target:match("^([^#]*)#(.*)$")
  if target then
    fragment = "#" .. fragment
  else
    target, fragment = el.target, ""
  end
  if not target:match("%.qmd$") then return el end

  local source = project_relative(quarto.doc.input_file or "")
  local page = resolve(dirname(source), target):gsub("%.qmd$", ".html")
  -- The staged projects are .build/id and .build/en; the English edition is
  -- published under /en/, so its links need that prefix.
  local prefix = (quarto.project.directory or ""):match("/en$") and "/en" or ""

  el.target = SITE .. prefix .. "/" .. page .. fragment
  return el
end
