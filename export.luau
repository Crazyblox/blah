--!strict
--!native

-- Returns a BLAH-encoded buffer as a requireable module source
return function(input: buffer): string
	local str: string = buffer.tostring(input)
	local match: number? = 1
	local count: number = 0
	local sep: string = string.rep([[=]], count)
	while match do
		count += 1
		sep = string.rep([[=]], count)
		match = string.find(str, sep, 0, true)
	end
	local s: string = string.rep([[=]], count)
	str = `return buffer.fromstring([{sep}[`..str..`]{sep}])`
	return str
end
