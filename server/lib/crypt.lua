#!/usr/bin/lua

local nixio = require "nixio"

salt = arg[1]
txt = io.read()

print (nixio.crypt(txt,salt))
