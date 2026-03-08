--!strict
--!native

return table.freeze {
	encode = require(`@self/encode`),
	decode = require(`@self/decode`),
	export = require(`@self/export`)
}

--[[ BLAH (Buffer Literals at Home)

[=[ ABOUT ]=]
	BLAH is a base256 -> base128 buffer codec which stores
raw data in the printable character range [32-255] by encoding
every 7 bytes into 8 bytes, where the 8th bit in each stored
byte is reserved as '1' to raise each byte out of the
non-printable character range.

	This allows for developers to store raw data via string literals
in cases where they wish to remain agnostic of a filesystem, or their
Luau environment literally doesn't support filesystem access, like Roblox :)

	The encoder does increase the byte size of raw data by ~14%; this is
the cost of making sure we avoid non-printable characters, though still a
better choice over storing via a base64 string, especially if paired with
a compression/decompression library before encoding.

	Code editors typically represent text in UTF8; do not worry about the
random symbols the encoded modules output; they're not meant to be
human-readable!

[=[ API ]=]	
	blah.encode(input: buffer): buffer
Takes the given input buffer and encodes the data into 8-byte chunks.
The encoded data is padded if the resulting byte size is not divisible by 8.
A 7 byte header is provided, with a u32 at byte 0 stating raw data size.
This header is then encoded as the first chunk of the output.

	blah.decode(input: buffer): buffer
Takes the given input buffer and decodes it into 7-byte chunks.
The header chunk is decoded and byte 0 is read, stating raw decoded file size.
Once complete, the output data will represent byte-for-byte what the original
data was before it was encoded, which... is pretty important...

	blah.export(input: buffer): string
Returns a buffer as a string which can be used as a requireable module source.
Ensure the provided buffer has been encoded by BLAH before exporting.
]]
