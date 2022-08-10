local path = require 'pandoc.path'
local utils = require 'pandoc.utils'
local stringify = utils.stringify

local function read_file (filename)
  local fh = io.open(filename)
  local content = fh:read('*a')
  fh:close()
  return content
end

local formats_by_extension = {
  md = 'markdown',
  latex = 'latex',
  native = 'haskell',
  tex = 'latex',
}

local function sample_blocks (sample_file)
  local sample_content = read_file(sample_file)
  local extension = select(2, path.split_extension(sample_file)):sub(2)
  local format = formats_by_extension[extension] or extension
  local filename = path.filename(sample_file)

  local sample_attr = pandoc.Attr('', {format, 'sample'})
  return {
    pandoc.Header(3, pandoc.Str(filename), {filename}),
    pandoc.CodeBlock(sample_content, sample_attr)
  }
end

local function result_blocks (result_file)
  local result_content = read_file(result_file)
  local extension = select(2, path.split_extension(result_file)):sub(2)
  local format = formats_by_extension[extension] or extension
  local filename = path.filename(result_file)

  local result_attr = pandoc.Attr('', {format, 'sample'})
  return {
    pandoc.Header(3, pandoc.Str(filename), {filename}),
    pandoc.CodeBlock(result_content, result_attr)
  }
end

local function code_blocks (code_file)
  local code_content = read_file(code_file)
  local code_attr = pandoc.Attr(code_file, {'lua'})
  return {
    pandoc.CodeBlock(code_content, code_attr)
  }
end

function Pandoc (doc)
  local meta = doc.meta
  local blocks = doc.blocks

  -- Set document title from README title. There should usually be just
  -- a single level 1 heading.
  blocks = blocks:walk{
    Header = function (h)
      if h.level == 1 then
        meta.title = h.content
        return {}
      end
    end
  }

  -- Add the sample file as an example.
  blocks:extend{pandoc.Header(2, 'Example', pandoc.Attr('Example'))}
  blocks:extend(sample_blocks(stringify(meta['sample-file'])))
  blocks:extend(result_blocks(stringify(meta['result-file'])))

  -- Add the filter code.
  local code_file = stringify(meta['code-file'])
  blocks:extend{pandoc.Header(2, 'Code', pandoc.Attr('Code'))}
  blocks:extend{pandoc.Para{pandoc.Link(pandoc.Str(code_file), code_file)}}
  blocks:extend(code_blocks(code_file))

  return pandoc.Pandoc(blocks, meta)
end
