--!strict
--!native

-- 0-based, reserved bit. Encode/decode functions require manual editing despite this value.
local res: number = 7
-- Size in bytes of encoded chunk and decoded chunk size
local encoded_chunk_size: number = 8
local raw_chunk_size: number = 7
-- For debugging purposes.
local output_binary = false
local debugging = false

local encode = {}

-- A chunk is 7 bytes decoded, 8 bytes encoded.
function encode.chunk(inBuffer: buffer, inCursor: number, outBuffer: buffer, outCursor: number)
	-- Read high bytes and low bytes; converts low bytes from u32 -> u24
	local hi: number = buffer.readu32(inBuffer, inCursor)
	local lo: number = bit32.lshift(buffer.readu16(inBuffer, inCursor + 4), 8) + buffer.readu8(inBuffer, inCursor + 6)
	-- Pack 8th byte with the reserved bit from each byte
	local bitpack: number = 
		bit32.lshift(bit32.extract(lo, 00+res), 0) + 
		bit32.lshift(bit32.extract(lo, 08+res), 1) +
		bit32.lshift(bit32.extract(lo, 16+res), 2) +
		bit32.lshift(bit32.extract(hi, 00+res), 3) +
		bit32.lshift(bit32.extract(hi, 08+res), 4) +
		bit32.lshift(bit32.extract(hi, 16+res), 5) +
		bit32.lshift(bit32.extract(hi, 24+res), 6)
	-- Setup encoded high bytes and low bytes, including bitpack in the 4th low byte.
	local hi_out = 0x80808080 + bit32.band(hi, 0x7F7F7F7F)
	local lo_out = 0x80808080 + bit32.lshift(bit32.band(lo, 0x007F7F7F), 8) + bitpack
	buffer.writeu32(outBuffer, outCursor, hi_out)
	buffer.writeu32(outBuffer, outCursor + 4, lo_out)
	-- For debugging, can be ignored.
	if debugging then
		for byte = 0, 7 do
			assert(buffer.readu8(outBuffer, outCursor + byte) ~= 0, `Uh oh... {outCursor + byte - encoded_chunk_size}`)
		end
		if outCursor < 200 then
			if output_binary then
				local buffer_read_hi: number = buffer.readu32(outBuffer, outCursor)
				local buffer_read_lo: number = buffer.readu32(outBuffer, outCursor + 4)
				local binary_out: string = ""
				-- Hi bytes
				for c = 24, 0, -8 do
					for bit = c+7, c+0, -1 do
						binary_out ..= bit32.extract(buffer_read_hi, bit)
					end 
					binary_out ..= "_"
				end
				-- Lo bytes
				for c = 24, 0, -8 do
					for bit = c+7, c+0, -1 do
						binary_out ..= bit32.extract(buffer_read_lo, bit)
					end 
					binary_out ..= "_"
				end
				print(`Buffer bytes {outCursor}-{outCursor + 7}: {binary_out}`)
			end
			print(`Reading from written buffer - {outCursor} hi: {buffer.readu32(outBuffer, outCursor)}`)
			print(`Reading from written buffer - {outCursor + 4} lo: {buffer.readu32(outBuffer, outCursor + 4)}`)
		end
	end
end

function encode.buffer(raw: buffer): buffer
	-- Locals
	local raw_size: number = buffer.len(raw)
	local read_size: number = raw_size
	local read: buffer = raw
	-- Padding: Add bytes if input byte size isn't divisible by 7
	if raw_size / 7 ~= raw_size // 7 then
		local padded: buffer = buffer.create(((raw_size // 7) + 1) * 7)
		buffer.fill(padded, 0, 0)
		buffer.copy(padded, 0, read)
		read = padded
		read_size = buffer.len(read)
	end
	print(`Raw bytes: {raw_size}, read bytes: {read_size}`)
	-- Header: Setup
	local header_bytes: buffer = buffer.create(raw_chunk_size)
	buffer.fill(header_bytes, 0, 0)
	buffer.writeu32(header_bytes, 0, raw_size)
	-- Header: Write as first encoded chunk
	local header_encoded: buffer = buffer.create(encoded_chunk_size)
	encode.chunk(header_bytes, 0, header_encoded, 0)
	local header_encoded_bytes: number = buffer.len(header_encoded)
	-- Output: Make buffer, add size of encoded header to size of buffer
	local write: buffer = buffer.create(((read_size // 7) * 8) + header_encoded_bytes)
	buffer.copy(write, 0, header_encoded)
	-- Output: Adjust write cursor after the encoded header chunk
	local write_c: number = 0 + header_encoded_bytes
	-- Output: Encoding loop
	print(`Created output buffer of size: {buffer.len(write)}, encoding...`)
	for read_c: number = 0, read_size - 1, raw_chunk_size do
		encode.chunk(read, read_c, write, write_c)
		write_c += encoded_chunk_size
	end
	-- Returns the encoded output buffer
	return write
end

return table.freeze(encode)
