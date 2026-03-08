--!strict
--!native
local decode_mini = [[local r,ec,rc,bw,bf=7,8,7,bit32,buffer local band,lsh,rsh,extr,ru32,ru8,wu32,wu16,wu8,len,wB=bw.band,bw.lshift,bw.rshift,bw.extract,bf.readu32,bf.readu8,bf.writeu32,bf.writeu16,bf.writeu8,bf.len,bf.create(8)
local function dC(iB:buffer,iC:number,oB:buffer,oC:number) local hi,lo=band(ru32(iB,iC),0x7F7F7F7F),band(ru32(iB,iC+4),0x7F7F7F7F) local bp=band(lo,0x7F) lo=rsh(lo,8)+lsh(extr(bp,0),r)+lsh(extr(bp,1),8+r)+lsh(extr(bp,2),16+r) hi+=lsh(extr(bp,3),r)+lsh(extr(bp,4),8+r)+lsh(extr(bp,5),16+r)+lsh(extr(bp,6),24+r) bf.fill(wB,0,0) wu32(wB,0,hi) wu16(wB,4,rsh(lo,8)) wu8(wB,6,band(lo,0xFF)) for B=0,6 do if oC>len(oB)-1 then break end wu8(oB,oC,ru8(wB,B)) oC+=1 end end
local function decode(r:buffer) local hDC=bf.create(7) dC(r,0,hDC,0) local s,wC,rs=ru32(hDC,0),0,len(r)-1 local w=bf.create(s) for iC=ec,rs,ec do dC(r,iC,w,wC) wC+=rc end return w end
]]

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
	return decode_mini .. `return decode(buffer.fromstring([{sep}[`..str..`]{sep}]))`
end
