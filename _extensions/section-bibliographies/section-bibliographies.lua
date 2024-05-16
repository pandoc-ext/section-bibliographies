--- section-bibliographies - chapter-wise reference sections
---
--- Copyright: © 2018 Jesse Rosenthal, 2020–2024 Albert Krewinkel
--- License: MIT – see LICENSE for details

-- pandoc.utils.citeproc exists since pandoc 2.19.1
PANDOC_VERSION:must_be_at_least {2,19,1}

local List = require 'pandoc.List'
local utils = require 'pandoc.utils'
local citeproc, sha1, stringify = utils.citeproc, utils.sha1, utils.stringify
local make_sections = function (doc, opts)
  return utils.make_sections(opts.number_sections, nil, doc.blocks)
end
if PANDOC_VERSION >= '3.0' then
  make_sections = (require 'pandoc.structure').make_sections
end

-- Returns true iff a div is a section div.
local function is_section_div (div)
  return div.t == 'Div'
    and div.classes[1] == 'section'
    and (div.attributes.number or div.classes:includes 'unnumbered')
end

--- Returns the section heading when given a section div, and nil otherwise.
-- @param div   a pandoc Block element
-- @return heading element or nil
local function section_header (div)
  local header = div.content and div.content[1]
  local is_header = is_section_div(div)
    and header
    and header.t == 'Header'
  return is_header and header or nil
end

--- Unwrap and remove section divs
local function flatten_sections (div)
  local header = section_header(div)
  if not header then
    return nil
  else
    header.identifier = div.identifier
    header.attributes.number = nil
    div.content[1] = header
    return div.content
  end
end

local function adjust_refs_components (div)
  local header = section_header(div)
  if not header then
    return div
  end
  local bib_header = div.content:find_if(function (b)
      return b.identifier == 'bibliography'
  end)
  local refs = div.content:find_if(function (b)
      return b.identifier == 'refs'
  end)
  local suffix = header.attributes.number
    or sha1(stringify(header.content))
  if bib_header then
    bib_header.identifier = 'bibliography-' .. suffix
    bib_header.level = header.level + 1
  end
  if refs and refs.identifier == 'refs' then
    refs.identifier = 'refs-' .. suffix
  end
  return div
end

--- Create a deep copy of a table.
-- Values that aren't tables are returned unchanged.
local function deepcopy (tbl)
  if type(tbl) ~= 'table' then
    return tbl
  end

  local copy = {}
  for k, v in pairs(tbl) do
    copy[k] = deepcopy(v)
  end
  return copy
end

-- negate a property
local negate = function (property)
  return function (x) return not property(x) end
end

--- Create a bibliography for a given section. This acts on all
-- section divs at or above `opts.level`
local function create_section_bibliography (meta, opts)
  local newmeta = deepcopy(meta)

  -- Load bibliography files just once.
  newmeta.bibliography = deepcopy(opts.bibliography)
  newmeta.references = deepcopy(opts.references)
  newmeta.nocite = pandoc.Inlines{
    pandoc.Cite('@*', {pandoc.Citation('*', 'NormalCitation')})
  }
  newmeta.references = utils.references(pandoc.Pandoc({}, newmeta))
  newmeta.bibliography = nil
  newmeta.nocite = nil

  -- Don't do anything if there is no bibliography
  if not next(newmeta.references) then
    return nil
  end

  local function section_citeproc(section)
    return citeproc(pandoc.Pandoc(section, newmeta)).blocks
  end

  local process_div
  process_div = function (div)
    local header = section_header(div)
    if not header or opts.level < header.level then
      -- Don't do anything for lower level sections.
      return div, false
    elseif opts.level == header.level then
      div.content = section_citeproc(div.content)
      return adjust_refs_components(div), false
    else
      div.content = section_citeproc(div.content:filter(negate(is_section_div)))
        .. div.content:filter(is_section_div):map(process_div)
      return adjust_refs_components(div), false
    end
  end

  return process_div
end

--- Filter to the references div and bibliography header added by
--- pandoc-citeproc.
local remove_pandoc_citeproc_results = {
  Header = function (header)
    return header.identifier == 'bibliography'
      and {}
      or nil
  end,
  Div = function (div)
    return div.identifier == 'refs'
      and {}
      or nil
  end
}

--- Create an options table from document metadata.
local function get_options (meta)
  local opts = meta['section-bibliographies'] or {}
  opts.bibliography = opts.bibliography
    or meta['section-bibs-bibliography']
    or meta['bibliography']
  opts.level = opts.level
    or tonumber(meta['section-bibs-level'])
    or 1
  opts.references = opts.references
    or meta['references']

  return opts
end

return {
  {
    Pandoc = function (doc)
      local opts = get_options(doc.meta)
      doc = doc:walk(remove_pandoc_citeproc_results)
      -- Setup the document for further processing by wrapping all
      -- sections in Div elements, but undo that after.
      doc.blocks = make_sections(doc, {number_sections=true})
        :walk{
          traverse = 'topdown',
          Div = create_section_bibliography(doc.meta, opts)
        }
        :walk{Div = flatten_sections}
      return doc
    end
  }
}
