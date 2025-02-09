
local prelude = [[
---@diagnostic disable: undefined-global, unused-local
local definedAlready
if _R and _D and _P and _PD and _MMAP and _M then
    definedAlready = true
else
    definedAlready = false
    _R=_R or {a=0,b=0,c=0,d=0,ss='\0',ds='\0',fn=function()end,f={gt=false,lt=false,ge=false,le=false,eq=false,ne=false,err=false,syserr=false},sp=65536}
    _D=_D or {}
    _P=_P or {}
    _PD=_PD or {}
    _S,_ST=nil,nil
    _MMAP=_MMAP or {{a=0,b=0,set=function()end,get=function()end},{a=1,b=81920,set=function(p,x) _D[p]=x end,get=function(p) return _D[p] end}}
    _M=_M or function(p,x)
        for i=#_MMAP,1,-1 do
            local v=_MMAP[i]
            if p>=v.a and p<=v.b then
            if x then v.set(p,x) else return v.get(p) end
            end
        end
    end
end
local id=function(...) return ... end
local asmcmp=function(a,b) return {lt=a<b,gt=a>b,le=a<=b,ge=a>=b,eq=a==b,ne=a~=b,err=false,syserr=false} end
local asmtest=function(a) local eq=a==0; return {lt=false,gt=false,le=eq,ge=eq,eq=eq,ne=not eq,err=false,syserr=false} end
local asmnot=function() return {lt=not _R.f.lt,gt=not _R.f.gt,le=not _R.f.le,ge=not _R.f.ge,eq=not _R.f.eq,ne=not _R.f.ne,err=false,syserr=false} end
local bit=bit or bit32
local unpck=table and table.unpack or unpack or unpck
local _Xargs,_Xnargs
if not bit then
    bit={}
    bit.bnot=id
    bit.band=id
    bit.bor=id
    bit.bxor=id
    bit.lshift=id
    bit.rshift=id
    bit.rol=id
    bit.ror=id
end
]]

local port_std = [[
if not definedAlready then 
    if os then
        if os.execute then _P[0x100]=function(a) _PD[0x100]=os.execute(a) end end
        if os.exit then _P[0x101]=function(a) os.exit(a) end end
        if os.getenv then _P[0x102]=function(a) _PD[0x102]=os.getenv(a) end end
        if os.time then _P[0x103]=function() _PD[0x103]=os.time() end end
    end
end
]]

_ASM = {}

pcall(function() table.unpack = table.unpack or unpack end)

_ASM.root = "./"
_ASM.label = 0x0
_ASM.labels = {}
_ASM.externs = {}

local parseline = require('include/parseline')
local genast = function(src, verbose)
    local line = 1
    local ast = {}
    local iter
    if type(src) == 'string' then
        iter = string.gmatch(src, '[^\n]*')
    elseif type(src) == 'function' then
        iter = src
    end

    local err = false
    for expr in iter do
        expr = string.gsub(expr, '%s*%-%-.*$', '')
        status, result = pcall(parseline, expr, verbose, line)
        if status and result then
            ast[#ast+1] = result
        elseif not status then
            print(result)
            err = true
        end
        line = line + 1
    end
    
    if err then
        error('invalid expression(s) in source file')
    end

    return ast
end

local assemble = require('include/assemble')
local compile = function(src, verbose, std, ports, mmap)
    _ASM.std = nil

    local prelude = prelude
    if type(std) == 'table' then
        _ASM.std = std
    elseif type(std) == 'string' then
        _ASM.std = {std}
    elseif std then
        _ASM.std = require('include/std')
        prelude = prelude .. port_std
        prelude = prelude .. 'if not definedAlready then _MMAP[#_MMAP+1]={a=81921,b=81921,set=function(_,v) print(v) end,get=id} end\n'
    end

    if _ASM.std then
        for _, v in pairs(_ASM.std) do
            prelude = prelude .. v .. '\n'
        end
    end

    local ast = genast(src, verbose)
    local asm = assemble(ast, verbose)

    if ports then
        for _, v in ipairs(ports) do
            prelude = prelude .. string.format('_P[%d]=%s\n',
                v.port or v[1], v.func or v[2])
        end
    end

    if mmap then
        for _, v in ipairs(mmap) do
            prelude = prelude .. string.format(
                'if not definedAlready then _MMAP[#_MMAP+1]={a=%d,b=%d,set=%s,get=%s} end\n',
                v.min or v[1],
                v.max or v[2],
                v.set or v[3] or 'function()end',
                v.get or v[4] or 'function()end')
        end
    end
    
    return prelude .. '\n' .. asm
end

return {compile = compile}
