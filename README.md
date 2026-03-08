I asked my mom if we could have buffer literals in Luau...
She said, "No, we have buffer literals at home".

'blah' encodes/decodes raw buffer data, which can then be exported as its own .luau module source for use in heavily sandboxed environments.

This is achieved by storing 7 bits for every byte, allowing us to store raw data as string literals exclusively in the printable character range.

'blah' can export encoded buffer data into this format, where upon requiring it, it will decode itself and return a buffer type, ready for the data to be used in Luau.
