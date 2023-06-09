local switch = function (expression)
	return function (cases)
		local defaultFunction, defaultArgs
		local open, closed = false, false

		for _, case in cases do
			local operation = case["OPERATION"]
			if open then
				case.FUNCTION(table.unpack(case.ARGS))
				if operation == "close" then
					closed = true
					break
				end
				continue
			end

			local caseType = case["TYPE"]
			local caseChecks = case["CHECKS"]

			if caseType == "default" then
				defaultFunction = case.FUNCTION
				defaultArgs = case.ARGS
				continue
			end

			if caseChecks and caseType == "case" then
				for _, check in caseChecks do
					if check == expression then
						if operation == "close" then
							closed = true
						elseif operation == "open" then
							open = true
						end

						case.FUNCTION(table.unpack(case.ARGS))
						break
					end
				end
			end
		end

		if not closed and defaultFunction then
			defaultFunction(table.unpack(defaultArgs))
		end
	end
end

local function caseAdder(case, firstArg, ...)
	local args = {...}

	-- Optimization: for loop unnecessary if it's only one argument
	local checkLength = #(case.checks)
	case.checks[checkLength + 1] = firstArg
	
	if args then
		checkLength += 1
		for _, value in args do
			checkLength += 1
			case.checks[checkLength] = value
		end
	end
	return case
end

local function closeOperation(self, caseFunction, ...)
	return {TYPE = self["type"], CHECKS = self["checks"], FUNCTION = caseFunction, ARGS = {...}, OPERATION = "close"}
end

local function openOperation(self, caseFunction, ...)
	return {TYPE = self["type"], CHECKS = self["checks"], FUNCTION = caseFunction, ARGS = {...}, OPERATION = "open"}
end

local case = function (...)
	return {
		-- Case Properties
		type = "case",
		checks = {...},

		-- Case Functions
		case = caseAdder,
		close = closeOperation,
		open = openOperation
	}
end

local default = {
	type = "default",
	close = closeOperation,
	open = openOperation
}

local returnTable = {switch, case, default}

return setmetatable(returnTable, {
	__call = function ()
		return table.unpack(returnTable)
	end
})