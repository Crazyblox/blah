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

local decode = {}

local working_bytes: buffer = buffer.create(8)
function decode.chunk(inBuffer: buffer, inCursor: number, outBuffer: buffer, outCursor: number)
	-- Fetch high bytes, low bytes & packed bits.
	local hi: number = bit32.band(buffer.readu32(inBuffer, inCursor), 0x7F7F7F7F)
	local lo: number = bit32.band(buffer.readu32(inBuffer, inCursor + 4), 0x7F7F7F7F)
	local bitpack: number = bit32.band(lo, 0x7F)
	-- Convert lo from u32 to u24
	lo = bit32.rshift(lo, 8)
	-- Redistribute packed bits to their original location
	lo +=
		bit32.lshift(bit32.extract(bitpack, 0), 00+res) +
		bit32.lshift(bit32.extract(bitpack, 1), 08+res) + 
		bit32.lshift(bit32.extract(bitpack, 2), 16+res)
	hi +=
		bit32.lshift(bit32.extract(bitpack, 3), 00+res) +
		bit32.lshift(bit32.extract(bitpack, 4), 08+res) +
		bit32.lshift(bit32.extract(bitpack, 5), 16+res) +
		bit32.lshift(bit32.extract(bitpack, 6), 24+res)
	-- Clear working bytes, then use to store decoded chunk.
	buffer.fill		(working_bytes, 0, 0x00)
	buffer.writeu32	(working_bytes, 0, hi)
	buffer.writeu16	(working_bytes, 4, bit32.rshift(lo, 8))
	buffer.writeu8	(working_bytes, 6, bit32.band(lo, 0xFF))
	-- Copy from working bytes to extent of output buffer
	for byte: number = 0, 6 do
		-- Prevents out-of-bounds buffer access when writing
		if outCursor > buffer.len(outBuffer)-1 then
			print(`Exiting writing to output buffer ({outCursor})`)
			break
		end
		buffer.writeu8(outBuffer, outCursor, buffer.readu8(working_bytes, byte))
		outCursor += 1
	end
end

function decode.buffer(read: buffer): buffer
	-- Header: Decode first chunk and read byte size of decoded data.
	local header_decoded: buffer = buffer.create(7)
	decode.chunk(read, 0, header_decoded, 0)
	-- Locals
	local raw_size: number = buffer.readu32(header_decoded, 0)
	local write_c: number = 0
	local read_size: number = buffer.len(read) - 1
	local write: buffer = buffer.create(raw_size)
	-- Output: Decoding loop
	print(`Read size: {read_size}, Output size: {raw_size}, decoding...`)
	for input_c: number = encoded_chunk_size, buffer.len(read) - 1, encoded_chunk_size do
		decode.chunk(read, input_c, write, write_c)
		write_c += raw_chunk_size
	end
	-- Returns the decoded output buffer
	return write
end

return table.freeze(decode)
