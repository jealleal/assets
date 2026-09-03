getgenv().decompile = function(script_instance)
    local bytecode = getscriptbytecode(script_instance)
    local encoded = crypt.base64.encode(bytecode)
    return request(
        {
            Url = "http://localhost:9004/decompile",
            Method = "POST",
            Body = encoded
        }
    ).Body
end
