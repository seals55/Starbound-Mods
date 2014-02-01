-- copies a table
-- a local table returned by a function stays in scope because wizards
-- should work if any of the keys are also tables, I don't think we're doing that anywhere though
-- it'll blow up if a table contains itself or a table containing itself or a table containing a table containing itself etc - again, let me know if that's an issue
function copyTable(source)
	local _copy
	if type(source) == "table" then
		_copy = {}
		for k, v in pairs(source) do
			_copy[copyTable(k)] = copyTable(v)
		end
	else
		_copy = source
	end
	return _copy
end