MySQL = MySQL or {}

local function isstring(t) return type(t) == "string" end
local function istable(t) return type(t) == "table" end
local function isnumber(t) return type(t) == "number" end

-- Query Builder

local QUERY_CLASS = {}
QUERY_CLASS.__index = QUERY_CLASS

function QUERY_CLASS:New(tableName, queryType)
	local newObject = setmetatable({}, QUERY_CLASS)
		newObject.queryType = queryType
		newObject.tableName = tableName
		newObject.selectList = {}
		newObject.insertList = {}
		newObject.updateList = {}
		newObject.createList = {}
		newObject.whereList = {}
		newObject.orderByList = {}
		newObject.valueList = {}
	return newObject
end

function QUERY_CLASS:ForTable(tableName)
	self.tableName = tableName
end

function QUERY_CLASS:Where(key, value)
	self:WhereEqual(key, value)
end

function QUERY_CLASS:WhereEqual(key, value)
	self.whereList[#self.whereList + 1] = "`" .. key .. "` = ?"
	self.valueList[#self.valueList + 1] = value
end

function QUERY_CLASS:WhereNotEqual(key, value)
	self.whereList[#self.whereList + 1] = "`" .. key .. "` != ?"
	self.valueList[#self.valueList + 1] = value
end

function QUERY_CLASS:WhereLike(key, value, format)
	format = format or "%%%s%%"
	self.whereList[#self.whereList + 1] = "`" .. key .. "` LIKE ?"
	self.valueList[#self.valueList + 1] = string.format(format, value)
end

function QUERY_CLASS:WhereNotLike(key, value, format)
	format = format or "%%%s%%"
	self.whereList[#self.whereList + 1] = "`" .. key .. "` NOT LIKE ?"
	self.valueList[#self.valueList + 1] = string.format(format, value)
end

function QUERY_CLASS:WhereGT(key, value)
	self.whereList[#self.whereList + 1] = "`" .. key .. "` > ?"
	self.valueList[#self.valueList + 1] = value
end

function QUERY_CLASS:WhereLT(key, value)
	self.whereList[#self.whereList + 1] = "`" .. key .. "` < ?"
	self.valueList[#self.valueList + 1] = value
end

function QUERY_CLASS:WhereGTE(key, value)
	self.whereList[#self.whereList + 1] = "`" .. key .. "` >= ?"
	self.valueList[#self.valueList + 1] = value
end

function QUERY_CLASS:WhereLTE(key, value)
	self.whereList[#self.whereList + 1] = "`" .. key .. "` <= ?"
	self.valueList[#self.valueList + 1] = value
end

function QUERY_CLASS:WhereIn(key, value)
	value = istable(value) and value or {value}

	local values = ""
	local bFirst = true

	for _, v in pairs(value) do
		values = values .. (bFirst and "" or ", ") .. "?"
		self.valueList[#self.valueList + 1] = v
		bFirst = false
	end

	self.whereList[#self.whereList + 1] = "`" .. key .. "` IN (" .. values .. ")"
end

function QUERY_CLASS:OrderByDesc(key)
	self.orderByList[#self.orderByList + 1] = "`" .. key .. "` DESC"
end

function QUERY_CLASS:OrderByAsc(key)
	self.orderByList[#self.orderByList + 1] = "`" .. key .. "` ASC"
end

function QUERY_CLASS:Callback(queryCallback)
	self.callback = queryCallback
end

function QUERY_CLASS:Select(fieldName)
	self.selectList[#self.selectList + 1] = "`" .. fieldName .. "`"
end

function QUERY_CLASS:Insert(key, value)
	self.insertList[#self.insertList + 1] = {"`" .. key .. "`", "?"}
	self.valueList[#self.valueList + 1] = value
end

function QUERY_CLASS:Update(key, value)
	self.updateList[#self.updateList + 1] = {"`" .. key .. "`", "?"}
	self.valueList[#self.valueList + 1] = value
end

function QUERY_CLASS:Create(key, value)
	self.createList[#self.createList + 1] = {"`" .. key .. "`", value}
end

function QUERY_CLASS:Add(key, value)
	self.add = {"`" .. key .. "`", value}
end

function QUERY_CLASS:Drop(key)
	self.drop = "`" .. key .. "`"
end

function QUERY_CLASS:PrimaryKey(key)
	self.primaryKey = "`" .. key .. "`"
end

function QUERY_CLASS:Limit(value)
	self.limit = value
end

function QUERY_CLASS:Offset(value)
	self.offset = value
end

local function BuildSelectQuery(queryObj)
	local queryString = {"SELECT"}

	if queryObj.count then
		queryString[#queryString + 1] = " " .. queryObj.count
	elseif (not istable(queryObj.selectList) or #queryObj.selectList == 0) then
		queryString[#queryString + 1] = " *"
	else
		queryString[#queryString + 1] = " " .. table.concat(queryObj.selectList, ", ")
	end

	if (isstring(queryObj.tableName)) then
		queryString[#queryString + 1] = " FROM `" .. queryObj.tableName .. "` "
	else
		print("[mysql] No table name specified!\n")
		return
	end

	if (istable(queryObj.whereList) and #queryObj.whereList > 0) then
		queryString[#queryString + 1] = " WHERE " .. table.concat(queryObj.whereList, " AND ")
	end

	if (istable(queryObj.orderByList) and #queryObj.orderByList > 0) then
		queryString[#queryString + 1] = " ORDER BY " .. table.concat(queryObj.orderByList, ", ")
	end

	if (isnumber(queryObj.limit)) then
		queryString[#queryString + 1] = " LIMIT " .. queryObj.limit
	end

	return table.concat(queryString)
end

local function BuildInsertQuery(queryObj, bIgnore)
	local suffix = (bIgnore and "INSERT IGNORE INTO" or "INSERT INTO")
	local queryString = {suffix}
	local keyList = {}
	local valueList = {}

	if (isstring(queryObj.tableName)) then
		queryString[#queryString + 1] = " `" .. queryObj.tableName .. "`"
	else
		print("[mysql] No table name specified!\n")
		return
	end

	for i = 1, #queryObj.insertList do
		keyList[#keyList + 1] = queryObj.insertList[i][1]
		valueList[#valueList + 1] = queryObj.insertList[i][2]
	end

	if (#keyList == 0) then
		return
	end

	queryString[#queryString + 1] = " (" .. table.concat(keyList, ", ") .. ") VALUES (" .. table.concat(valueList, ", ") .. ")"

	return table.concat(queryString)
end

local function BuildUpdateQuery(queryObj)
	local queryString = {"UPDATE"}

	if (isstring(queryObj.tableName)) then
		queryString[#queryString + 1] = " `" .. queryObj.tableName .. "`"
	else
		print("[mysql] No table name specified!\n")
		return
	end

	if (istable(queryObj.updateList) and #queryObj.updateList > 0) then
		local updateList = {}

		queryString[#queryString + 1] = " SET"

		for i = 1, #queryObj.updateList do
			updateList[#updateList + 1] = queryObj.updateList[i][1] .. " = " .. queryObj.updateList[i][2]
		end

		queryString[#queryString + 1] = " " .. table.concat(updateList, ", ")
	end

	if (istable(queryObj.whereList) and #queryObj.whereList > 0) then
		queryString[#queryString + 1] = " WHERE " .. table.concat(queryObj.whereList, " AND ")
	end

	if (isnumber(queryObj.offset)) then
		queryString[#queryString + 1] = " OFFSET " .. queryObj.offset
	end

	return table.concat(queryString)
end

local function BuildDeleteQuery(queryObj)
	local queryString = {"DELETE FROM"}

	if (isstring(queryObj.tableName)) then
		queryString[#queryString + 1] = " `" .. queryObj.tableName .. "`"
	else
		print("[mysql] No table name specified!\n")
		return
	end

	if (istable(queryObj.whereList) and #queryObj.whereList > 0) then
		queryString[#queryString + 1] = " WHERE " .. table.concat(queryObj.whereList, " AND ")
	end

	if (isnumber(queryObj.limit)) then
		queryString[#queryString + 1] = " LIMIT " .. queryObj.limit
	end

	return table.concat(queryString)
end

local function BuildDropQuery(queryObj)
	local queryString = {"DROP TABLE"}

	if (isstring(queryObj.tableName)) then
		queryString[#queryString + 1] = " `" .. queryObj.tableName .. "`"
	else
		print("[mysql] No table name specified!\n")
		return
	end

	return table.concat(queryString)
end

local function BuildTruncateQuery(queryObj)
	local queryString = {"TRUNCATE TABLE"}

	if (isstring(queryObj.tableName)) then
		queryString[#queryString + 1] = " `" .. queryObj.tableName .. "`"
	else
		print("[mysql] No table name specified!\n")
		return
	end

	return table.concat(queryString)
end

local function BuildCreateQuery(queryObj)
	local queryString = {"CREATE TABLE IF NOT EXISTS"}

	if (isstring(queryObj.tableName)) then
		queryString[#queryString + 1] = " `" .. queryObj.tableName .. "`"
	else
		print("[mysql] No table name specified!\n")
		return
	end

	queryString[#queryString + 1] = " ("

	if (istable(queryObj.createList) and #queryObj.createList > 0) then
		local createList = {}

		for i = 1, #queryObj.createList do
			createList[#createList + 1] = queryObj.createList[i][1] .. " " .. queryObj.createList[i][2]
		end

		queryString[#queryString + 1] = " " .. table.concat(createList, ", ")
	end

	if (isstring(queryObj.primaryKey)) then
		queryString[#queryString + 1] = ", PRIMARY KEY (" .. queryObj.primaryKey .. ")"
	end

	queryString[#queryString + 1] = " )"

	return table.concat(queryString)
end

local function BuildAlterQuery(queryObj)
	local queryString = {"ALTER TABLE"}

	if (isstring(queryObj.tableName)) then
		queryString[#queryString + 1] = " `" .. queryObj.tableName .. "`"
	else
		print("[mysql] No table name specified!\n")
		return
	end

	if (istable(queryObj.add)) then
		queryString[#queryString + 1] = " ADD " .. queryObj.add[1] .. " " .. queryObj.add[2]
	elseif (isstring(queryObj.drop)) then
		queryString[#queryString + 1] = " DROP COLUMN " .. queryObj.drop
	end

	return table.concat(queryString)
end

function QUERY_CLASS:Execute()
	local queryString = nil
	local queryType = string.lower(self.queryType)

	if (queryType == "select") then
		queryString = BuildSelectQuery(self)
	elseif (queryType == "insert") then
		queryString = BuildInsertQuery(self)
	elseif (queryType == "insert ignore") then
		queryString = BuildInsertQuery(self, true)
	elseif (queryType == "update") then
		queryString = BuildUpdateQuery(self)
	elseif (queryType == "delete") then
		queryString = BuildDeleteQuery(self)
	elseif (queryType == "drop") then
		queryString = BuildDropQuery(self)
	elseif (queryType == "truncate") then
		queryString = BuildTruncateQuery(self)
	elseif (queryType == "create") then
		queryString = BuildCreateQuery(self)
	elseif (queryType == "alter") then
		queryString = BuildAlterQuery(self)
	end

	if (isstring(queryString)) then
		MySQL.query(queryString, self.valueList, self.callback)
	end
end

-- Inteface
function MySQL:Select(tableName)
	return QUERY_CLASS:New(tableName, "SELECT")
end

function MySQL:Insert(tableName)
	return QUERY_CLASS:New(tableName, "INSERT")
end

function MySQL:InsertIgnore(tableName)
	return QUERY_CLASS:New(tableName, "INSERT IGNORE")
end

function MySQL:Update(tableName)
	return QUERY_CLASS:New(tableName, "UPDATE")
end

function MySQL:Delete(tableName)
	return QUERY_CLASS:New(tableName, "DELETE")
end

function MySQL:Drop(tableName)
	return QUERY_CLASS:New(tableName, "DROP")
end

function MySQL:Truncate(tableName)
	return QUERY_CLASS:New(tableName, "TRUNCATE")
end

function MySQL:Create(tableName)
	return QUERY_CLASS:New(tableName, "CREATE")
end

function MySQL:Alter(tableName)
	return QUERY_CLASS:New(tableName, "ALTER")
end