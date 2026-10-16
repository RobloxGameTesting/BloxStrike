--!native
local Winding = require(script.Parent:WaitForChild("Winding"))
local Portals = {}

local function addPortalToNodes(portals, p, p2) -- 10 equivalent calls inferred from this helper
	portals.nodes[1] = p
	portals.next[1] = p.portals
	p.portals = portals
	portals.nodes[2] = p2
	portals.next[2] = p2.portals
	p2.portals = portals
end

local function removePortalFromNode(p, p2)
	local portals = p2.portals
	local v = nil
	local v2 = nil

	while portals ~= nil and portals ~= p do
		v2 = portals.nodes[1] == p2 and 1 or 2
		v = portals
		portals = portals.next[v2]
	end

	assert(portals == p, "portal not in node list")
	local v3 = p.nodes[1] == p2 and 1 or 2

	if v == nil then
		p2.portals = p.next[v3]
	else
		v.next[v2] = p.next[v3]
	end

	p.next[v3] = nil
	p.nodes[v3] = nil
end

local function newPortal(plane, p)
	return { plane = plane, w = p, nodes = {}, next = {} }
end

local function nodePortals(p)
	local portals = p.portals
	local portals2 = {}

	while portals ~= nil do
		portals2[#portals2 + 1] = portals
		portals = portals.next[portals.nodes[1] == p and 1 or 2]
	end

	return portals2
end

local function makeHeadnodePortals(p, p2, p3, p4, p5, p6, p7, p8)
	local v = { p3 - 0, p4 - 0, p5 - 0 }
	local v2 = { p6 + 0, p7 + 0, p8 + 0 }
	local v3 = {}
	local v4 = {}

	for i = 1, 3 do
		for j = 0, 1 do
			local plane = { 0, 0, 0, 0 }

			if j == 1 then
				plane[i] = -1
				plane[4] = -v2[i]
			else
				plane[i] = 1
				plane[4] = v[i]
			end

			local v5 = j * 3 + i
			v3[v5] = plane
			local portals = newPortal(plane, Winding.baseForPlane(plane[1], plane[2], plane[3], plane[4]))
			v4[v5] = portals
			addPortalToNodes(portals, p, p2) -- inferred equivalent call
		end
	end

	for i = 1, 6 do
		for j = 1, 6 do
			if i == j then
				continue
			end

			local v5 = v3[j]
			v4[i].w = Winding.clip(v4[i].w, v5[1], v5[2], v5[3], v5[4], 0.001)
		end
	end
end

local function makeNodePortal(data, state)
	local plane = data.plane
	local baseForPlane = Winding.baseForPlane(plane[1], plane[2], plane[3], plane[4])

	for _, v in nodePortals(data) do
		local plane2 = v.plane

		if v.nodes[1] == data then
			baseForPlane = Winding.clip(baseForPlane, plane2[1], plane2[2], plane2[3], plane2[4], 0.001)
		else
			baseForPlane = Winding.clip(baseForPlane, -plane2[1], -plane2[2], -plane2[3], -plane2[4], 0.001)
		end

		if baseForPlane == nil then
			break
		end
	end

	if baseForPlane == nil then
		state.clippedAway += 1
		return
	end

	if Winding.area(baseForPlane) < 1e-6 then
		state.tinyPortals += 1
		return
	end

	addPortalToNodes(newPortal(plane, baseForPlane), data.front, data.back) -- inferred equivalent call
end

local function splitNodePortals(data, state)
	local plane = data.plane
	local front = data.front
	local back = data.back

	for _, v in nodePortals(data) do
		local v2 = v.nodes[1] == data and 1 or 2
		local node = v.nodes[3 - v2]
		removePortalFromNode(v, v.nodes[1])
		removePortalFromNode(v, v.nodes[2])
		local parts, v3 = Winding.split(v.w, plane[1], plane[2], plane[3], plane[4], 0.001)

		if parts ~= nil and Winding.area(parts) < 1e-6 then
			state.tinyPortals += 1
			parts = nil
		end

		if v3 ~= nil and Winding.area(v3) < 1e-6 then
			state.tinyPortals += 1
			v3 = nil
		end

		if not (parts ~= nil or v3 ~= nil) then
			continue
		end

		if parts == nil then
			v.w = v3

			if v2 == 1 then
				addPortalToNodes(v, back, node) -- inferred equivalent call
			else
				addPortalToNodes(v, node, back) -- inferred equivalent call
			end
		elseif v3 == nil then
			v.w = parts

			if v2 == 1 then
				addPortalToNodes(v, front, node) -- inferred equivalent call
			else
				addPortalToNodes(v, node, front) -- inferred equivalent call
			end
		else
			local portals = newPortal(v.plane, v3)
			v.w = parts

			if v2 == 1 then
				addPortalToNodes(v, front, node) -- inferred equivalent call
				addPortalToNodes(portals, back, node) -- inferred equivalent call
			else
				addPortalToNodes(v, node, front) -- inferred equivalent call
				addPortalToNodes(portals, node, back) -- inferred equivalent call
			end

			state.splitPortals += 1
		end
	end
end

local function makeTreePortals(data, result, callback)
	if data.leaf then
		return
	end

	result.visited += 1

	if callback ~= nil and result.visited % 4 == 0 then
		callback()
	end

	makeNodePortal(data, result)
	splitNodePortals(data, result)
	makeTreePortals(data.front, result, callback)
	makeTreePortals(data.back, result, callback)
end

function Portals.build(p, items, p2, p3, p4, p5, p6, p7, p8)
	local result = {
		clippedAway = 0,
		tinyPortals = 0,
		splitPortals = 0,
		airPortals = 0,
		solidPortals = 0,
		visited = 0
	}
	makeHeadnodePortals(p, {
		leaf = true,
		air = false,
		outside = true,
		portals = nil,
		planes = {}
	}, p2, p3, p4, p5, p6, p7)
	makeTreePortals(p, result, p8)
	local v = {}
	local result2 = {}

	for _, item in items do
		if not item.air then
			continue
		end

		for _, v2 in nodePortals(item) do
			if v[v2] then
				continue
			end

			v[v2] = true
			local node = v2.nodes[1]
			local node2 = v2.nodes[2]

			if node.air and node2.air then
				result.airPortals += 1
				result2[#result2 + 1] = { front = node, back = node2, plane = v2.plane, w = v2.w }
			else
				result.solidPortals += 1
			end
		end
	end

	return result2, result
end

return Portals