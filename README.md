# fivesql
A MySQL wrapper for FiveM FX Server using oxmysql, based on https://github.com/alexgrist/GLua-MySQL-Wrapper

---
### Easy Query Building
Examples:

* Create table
```lua
local query = MySQL:Create("players")
	query:Create("id", "INT NOT NULL AUTO_INCREMENT")
	query:Create("name", "VARCHAR(255) NOT NULL")
	query:Create("money", "INT(11)")
	query:PrimaryKey("id")
query:Execute()
```

* Select query
```lua
local query = MySQL:Select("players")
	query:Select("name")
	query:Where("id", 93)
	query:Callback(function(result)
		-- handle result
	end)
query:Execute()
```

* Insert query
```lua
local query = MySQL:Insert("players")
	query:Insert("name", "wolfy")
	query:Insert("money", 10000)
    query:Callback(function(result)
        print("done!")
    end)
query:Execute()
```

* Update query
```lua
local query = MySQL:Update("players")
	query:Update("money", 5000)
	query3:WhereGT("id", 20)
	query3:Callback(function()
		print("done!")
	end)
query:Execute()
```
