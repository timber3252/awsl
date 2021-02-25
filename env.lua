local env = {}

env.moduleDir = debug.getinfo(1, 'S').source:match[[^@(.*/).*$]]
env.scriptsDir = env.moduleDir .. 'scripts/'

return env