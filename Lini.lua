--- load file to lines
---@param path string
---@return table
local function load_file_to_lines(path)
	local f = io.open(path, "r")
	local lines = {}
	local line = f:read("l")
	while line do
	  table.insert(lines, line)
	  line = f:read("l")
	end
  f:close()
	return lines
end

---@param t table
---@return integer
local function table_len(t)
	local l = 0
	for _, _ in ipairs(t) do l = l + 1 end
	return l
end

---@param str string
---@return boolean
local function isalnum(str)
	for i = 1, string.len(str) do
		local ch = string.sub(str, i, i)
		if not (('a' <= ch and ch <= 'z') or ('A' <= ch and ch <= 'Z') or ('0' <= ch and ch <= '9')) then
			return false
		end
	end
	return true
end

---@param input string
---@param delimiter string
---@return table
local function split(input, delimiter)
	if delimiter == "" then return false end
	local pos, arr = 0, {}
	for st, sp in function() return string.find(input, delimiter, pos, true) end do
		table.insert(arr, string.sub(input, pos, st - 1))
		pos = sp + 1
	end
	table.insert(arr, string.sub(input, pos))
	return arr
end

---@param s string
---@return string
local function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local module = {}

local Error_type = {
  syntax_error = 'syntax error',
}

--- format error
---@param err_t string
---@param msg string
---@param line string
---@param line_num integer
local function Lini_error(err_t, msg, line, line_num)
  error(err_t .. ': ' .. msg .. ' in line ' .. tostring(line_num) .. ':\n' .. line)
end

--- parse a line
---@param line string
---@param line_num integer
---@param t table
---@return table
local function parse_line(line, line_num, t, now_sc)
  local comment = string.find(line, ';')
  if comment then
    line = string.sub(line, 1, comment-1)
  end
  line = trim(line)
  if line == '' then
    return
  end

  if string.sub(line, 1, 1) == '[' then
    if string.sub(line, -1,-1) ~= ']' then
      Lini_error(Error_type.syntax_error, 'no \']\'', line, line_num)
    end
    now_sc = t
    local name = string.sub(line, 2, -2)
    name = split(name, '.')
    for _, sc in ipairs(name) do
      if not isalnum(sc) then
        Lini_error(Error_type.syntax_error, 'unexpected section name: ' .. sc, line, line_num)
      end
      if now_sc[sc] == nil then
        now_sc[sc] = {}
      end
      now_sc = now_sc[sc]
    end
    return now_sc
  end

  local tmp = split(line, '=')
  tmp[1] = trim(tmp[1])
  tmp[2] = trim(tmp[2])
  if table_len(tmp) > 2 then
    Lini_error(Error_type.syntax_error, 'to many \'=\'', line, line_num)
  end
  if tmp[1] == '' then
    Lini_error(Error_type.syntax_error, 'null key', line, line_num)
  end
  if tmp[2] == '' then
    Lini_error(Error_type.syntax_error, 'null value', line, line_num)
  end
  if now_sc == nil then
    now_sc = t
  end
  now_sc[tmp[1]] = tmp[2]
  return now_sc
end

--- load ini from lines table
---@param lines table
---@return table
local function load_from_lines(lines)
  local r = {}
  local now_sc = nil
  for line_num ,i in ipairs(lines) do
    i = trim(i)
    if i == '' then
      goto continue
    end
    now_sc = parse_line(i, line_num, r, now_sc)
    ::continue::
  end
  return r
end

--- load ini from string
---@param str string
---@return table
function module.load_from_string(str)
  str = trim(str)
  if string.sub(str, -1, -1) == '\n' then
    if string.len(str) > 1 then
      str = string.sub(str, 1, -2)
    else
      str = ''
    end
  end
  return load_from_lines(split(str, '\n'))
end

--- load ini from ini file
---@param path string
---@return table
function module.load_from_file(path)
  -- dbg()
  return load_from_lines(load_file_to_lines(path))
end

--- from table to ini string
---@param t table
---@return string
function module.write(t)
  local r = ''
  local sections = {}
  for k, v in pairs(t) do
    if type(v) == 'table' then
      sections[k] = v
      goto continue
    end
    r = r .. tostring(k) .. '=' .. tostring(v) .. '\n'
    ::continue::
  end

  function table_to_section(name, t)
    local r = '[' .. name .. ']\n'
    local sub_sections = {}
    for k, v in pairs(t) do
      if type(v) == 'table' then
        sub_sections[name .. '.' .. tostring(k)] = v
        goto continue
      end
      r = r .. tostring(k) .. '=' .. tostring(v) .. '\n'
      ::continue::
    end

    for k, v in pairs(sub_sections) do
      r = r .. table_to_section(k, v)
    end

    return r
  end

  for k, v in pairs(sections) do
    r = r .. table_to_section(k, v)
  end

  return r
end

--- write table in ini format to file
---@param path string
---@param t table
function module.write_to_file( path, t)
  local f = io.open(path, 'w')
  f:write(module.write(t))
  f:close()
end

return module