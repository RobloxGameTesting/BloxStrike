return function()
	local parentModule = require(script.Parent)
	describe("Copy (Deep)", function()
		it("should create a deep table copy", function()
			local v = {
				a = {
					b = {
						c = { d = 32 }
					}
				}
			}
			local copy = parentModule.Copy(v, true)
			expect(v).never.to.equal(copy)
			expect(v.a).never.to.equal(copy.a)
			expect(copy.a.b.c.d).to.equal(v.a.b.c.d)
		end)
	end)
	describe("Copy (Shallow)", function()
		it("should create a shallow dictionary copy", function()
			local v = {
				a = {
					b = {
						c = { d = 32 }
					}
				}
			}
			local copy = parentModule.Copy(v)
			expect(copy).never.to.equal(v)
			expect(copy.a).to.equal(v.a)
			expect(copy.a.b.c.d).to.equal(v.a.b.c.d)
		end)
		it("should create a shallow array copy", function()
			local v = { 10, 20, 30, 40 }
			local copy = parentModule.Copy(v)
			expect(copy).never.to.equal(v)

			for i, v2 in ipairs(v) do
				expect(copy[i]).to.equal(v2)
			end
		end)
	end)
	describe("Sync", function()
		it("should sync tables", function()
			local v = {
				a = 32,
				b = 64,
				c = 128,
				e = { h = 1 }
			}
			local v2 = parentModule.Sync({
				a = 32,
				b = 10,
				d = 1,
				e = { h = 2, n = 2 },
				f = { x = 10 }
			}, v)
			expect(v2.a).to.equal(v.a)
			expect(v2.b).to.equal(10)
			expect(v2.c).to.equal(v.c)
			expect(v2.d).never.to.be.ok()
			expect(v2.e.h).to.equal(2)
			expect(v2.e.n).never.to.be.ok()
			expect(v2.f).never.to.be.ok()
		end)
	end)
	describe("Reconcile", function()
		it("should reconcile table", function()
			local v = {
				kills = 0,
				deaths = 0,
				xp = 10,
				stuff = {},
				stuff2 = "abc",
				stuff3 = { "data" }
			}
			local v2 = {
				kills = 10,
				deaths = 4,
				stuff = { "abc", "xyz" },
				extra = 5,
				stuff2 = { abc = 10 },
				stuff3 = true
			}
			local v3 = parentModule.Reconcile(v2, v)
			expect(v3).never.to.equal(v2)
			expect(v3).never.to.equal(v)
			expect(v3.kills).to.equal(10)
			expect(v3.deaths).to.equal(4)
			expect(v3.xp).to.equal(10)
			expect(v3.stuff[1]).to.equal("abc")
			expect(v3.stuff[2]).to.equal("xyz")
			expect(v3.extra).to.equal(5)
			expect((type(v3.stuff2))).to.equal("table")
			expect(v3.stuff2).never.to.equal(v2.stuff2)
			expect(v3.stuff2.abc).to.equal(10)
			expect((type(v3.stuff3))).to.equal("boolean")
			expect(v3.stuff3).to.equal(true)
		end)
	end)
	describe("SwapRemove", function()
		it("should swap remove index", function()
			local v = { 1, 2, 3, 4, 5 }
			parentModule.SwapRemove(v, 3)
			expect(#v).to.equal(4)
			expect(v[3]).to.equal(5)
		end)
	end)
	describe("SwapRemoveFirstValue", function()
		it("should swap remove first value given", function()
			local v = { "hello", "world", "goodbye", "planet" }
			parentModule.SwapRemoveFirstValue(v, "world")
			expect(#v).to.equal(3)
			expect(v[2]).to.equal("planet")
		end)
	end)
	describe("Map", function()
		it("should map table", function()
			local mapped = parentModule.Map({
				{ FirstName = "John", LastName = "Doe" },
				{ FirstName = "Jane", LastName = "Smith" }
			}, function(p)
				return p.FirstName .. " " .. p.LastName
			end)
			expect(mapped[1]).to.equal("John Doe")
			expect(mapped[2]).to.equal("Jane Smith")
		end)
	end)
	describe("Filter", function()
		it("should filter table", function()
			local filtered = parentModule.Filter({
				10,
				20,
				30,
				40,
				50,
				60,
				70,
				80,
				90
			}, function(p)
				return p >= 30 and p <= 60
			end)
			expect(#filtered).to.equal(4)
			expect(filtered[1]).to.equal(30)
			expect(filtered[#filtered]).to.equal(60)
		end)
	end)
	describe("Reduce", function()
		it("should reduce table with numbers", function()
			local reduced = parentModule.Reduce({ 1, 2, 3, 4, 5 }, function(p, p2)
				return p + p2
			end)
			expect(reduced).to.equal(15)
		end)
		it("should reduce table", function()
			local reduced = parentModule.Reduce({
				{ Score = 10 },
				{ Score = 20 },
				{ Score = 30 }
			}, function(p, p2)
				return p + p2.Score
			end, 0)
			expect(reduced).to.equal(60)
		end)
		it("should reduce table with initial value", function()
			local reduced = parentModule.Reduce({
				{ Score = 10 },
				{ Score = 20 },
				{ Score = 30 }
			}, function(p, p2)
				return p + p2.Score
			end, 40)
			expect(reduced).to.equal(100)
		end)
		it("should reduce functions", function()
			local function Square(p)
				return p * p
			end

			local function Double(p)
				return p * 2
			end

			local v = parentModule.Reduce({ Square, Double }, function(callback, callback2)
				return function(p)
					return callback(callback2(p))
				end
			end)(10)
			expect(v).to.equal(400)
		end)
	end)
	describe("Assign", function()
		it("should assign tables", function()
			local v = parentModule.Assign({ a = 32, x = 100 }, { b = 64, c = 128 }, {
				a = 10,
				c = 100,
				d = 200
			})
			expect(v.a).to.equal(10)
			expect(v.b).to.equal(64)
			expect(v.c).to.equal(100)
			expect(v.d).to.equal(200)
			expect(v.x).to.equal(100)
		end)
	end)
	describe("Extend", function()
		it("should extend tables", function()
			local extended = parentModule.Extend({ "a", "b", "c" }, { "d", "e", "f" })
			expect(table.concat(extended)).to.equal("abcdef")
		end)
	end)
	describe("Reverse", function()
		it("should create a table in reverse", function()
			local reversed = parentModule.Reverse({ 1, 2, 3 })
			expect(table.concat(reversed)).to.equal("321")
		end)
	end)
	describe("Shuffle", function()
		it("should shuffle a table", function()
			local v = { 1, 2, 3, 4, 5 }
			expect(function()
				parentModule.Shuffle(v)
			end).never.to.throw()
		end)
	end)
	describe("Sample", function()
		it("should sample a table", function()
			local sample = parentModule.Sample({ 1, 2, 3, 4, 5 }, 3)
			expect(#sample).to.equal(3)
		end)
	end)
	describe("Flat", function()
		it("should flatten table", function()
			local flat = parentModule.Flat({
				1,
				2,
				3,
				{
					4,
					5,
					{ 6, 7 }
				}
			}, 3)
			expect(table.concat(flat)).to.equal("1234567")
		end)
	end)
	describe("FlatMap", function()
		it("should map and flatten table", function()
			local flatMap = parentModule.FlatMap({ 1, 2, 3, 4, 5, 6, 7 }, function(p)
				return { p, p * 2 }
			end)
			expect(table.concat(flatMap)).to.equal("12243648510612714")
		end)
	end)
	describe("Keys", function()
		it("should give all keys of table", function()
			local keys = parentModule.Keys({ a = 1, b = 2, c = 3 })
			expect(#keys).to.equal(3)
			expect(table.find(keys, "a")).to.be.ok()
			expect(table.find(keys, "b")).to.be.ok()
			expect(table.find(keys, "c")).to.be.ok()
		end)
	end)
	describe("Values", function()
		it("should give all values of table", function()
			local values = parentModule.Values({ a = 1, b = 2, c = 3 })
			expect(#values).to.equal(3)
			expect(table.find(values, 1)).to.be.ok()
			expect(table.find(values, 2)).to.be.ok()
			expect(table.find(values, 3)).to.be.ok()
		end)
	end)
	describe("Find", function()
		it("should find item in array", function()
			local v, v2 = parentModule.Find({ 10, 20, 30 }, function(p)
				return p == 20
			end)
			expect(v).to.be.ok()
			expect(v2).to.equal(2)
			expect(v).to.equal(20)
		end)
		it("should find item in dictionary", function()
			local v, v2 = parentModule.Find({
				{ Score = 10 },
				{ Score = 20 },
				{ Score = 30 }
			}, function(p)
				return p.Score == 20
			end)
			expect(v).to.be.ok()
			expect(v2).to.equal(2)
			expect(v.Score).to.equal(20)
		end)
	end)
	describe("Every", function()
		it("should see every value is above 20", function()
			local every = parentModule.Every({ 21, 40, 200 }, function(p)
				return p > 20
			end)
			expect(every).to.equal(true)
		end)
		it("should see every value is not above 20", function()
			local every = parentModule.Every({ 20, 40, 200 }, function(p)
				return p > 20
			end)
			expect(every).never.to.equal(true)
		end)
	end)
	describe("Some", function()
		it("should see some value is above 20", function()
			local some = parentModule.Some({ 5, 40, 1 }, function(p)
				return p > 20
			end)
			expect(some).to.equal(true)
		end)
		it("should see some value is not above 20", function()
			local some = parentModule.Some({ 5, 15, 1 }, function(p)
				return p > 20
			end)
			expect(some).never.to.equal(true)
		end)
	end)
	describe("Truncate", function()
		it("should truncate an array", function()
			local v = { 1, 2, 3, 4, 5 }
			local truncate = parentModule.Truncate(v, 3)
			expect(#truncate).to.equal(3)
			expect(truncate[1]).to.equal(v[1])
			expect(truncate[2]).to.equal(v[2])
			expect(truncate[3]).to.equal(v[3])
		end)
		it("should truncate an array with out of bounds sizes", function()
			local v = { 1, 2, 3, 4, 5 }
			expect(function()
				parentModule.Truncate(v, -1)
			end).to.never.throw()
			expect(function()
				parentModule.Truncate(v, #v + 1)
			end).to.never.throw()
			local truncate = parentModule.Truncate(v, #v + 10)
			expect(#truncate).to.equal(#v)
			expect(truncate).to.never.equal(v)
		end)
	end)
	describe("Lock", function()
		it("should lock a table", function()
			local v = {
				abc = {
					xyz = { num = 32 }
				}
			}
			expect(function()
				v.abc.xyz.num = 64
			end).never.to.throw()
			local v2 = parentModule.Lock(v)
			expect(v.abc.xyz.num).to.equal(64)
			expect(v).to.equal(v2)
			expect(function()
				v.abc.xyz.num = 10
			end).to.throw()
		end)
	end)
	describe("Zip", function()
		it("should zip arrays together", function()
			local v = { 1, 2, 3, 4, 5 }
			local v2 = { 9, 8, 7, 6, 5 }
			local v3 = { 1, 1, 1, 1, 1 }
			local v4 = 0

			for k, v5 in parentModule.Zip(v, v2, v3) do
				expect(v5[1]).to.equal(v[k])
				expect(v5[2]).to.equal(v2[k])
				expect(v5[3]).to.equal(v3[k])
				v4 = k
			end

			expect(v4).to.equal((math.min(#v, #v2, #v3)))
		end)
		it("should zip arrays of different lengths together", function()
			local v = { 1, 2, 3, 4, 5 }
			local v2 = { 9, 8, 7, 6 }
			local v3 = { 1, 1, 1 }
			local v4 = 0

			for k, v5 in parentModule.Zip(v, v2, v3) do
				expect(v5[1]).to.equal(v[k])
				expect(v5[2]).to.equal(v2[k])
				expect(v5[3]).to.equal(v3[k])
				v4 = k
			end

			expect(v4).to.equal((math.min(#v, #v2, #v3)))
		end)
		it("should zip maps together", function()
			local v = { a = 10, b = 20, c = 30 }
			local v2 = { a = 100, b = 200, c = 300 }
			local v3 = { a = 3000, b = 2000, c = 3000 }

			for k, v4 in parentModule.Zip(v, v2, v3) do
				expect(v4[1]).to.equal(v[k])
				expect(v4[2]).to.equal(v2[k])
				expect(v4[3]).to.equal(v3[k])
			end
		end)
		it("should zip maps of different keys together", function()
			local v = { a = 10, b = 20, c = 30, d = 40 }
			local v2 = { a = 100, b = 200, c = 300, z = 10 }
			local v3 = { a = 3000, b = 2000, c = 3000, x = 0 }

			for k, v4 in parentModule.Zip(v, v2, v3) do
				expect(v4[1]).to.equal(v[k])
				expect(v4[2]).to.equal(v2[k])
				expect(v4[3]).to.equal(v3[k])
			end
		end)
	end)
	describe("IsEmpty", function()
		it("should detect that table is empty", function()
			local isEmpty = parentModule.IsEmpty({})
			expect(isEmpty).to.equal(true)
		end)
		it("should detect that array is not empty", function()
			local isEmpty = parentModule.IsEmpty({ 10, 20, 30 })
			expect(isEmpty).to.equal(false)
		end)
		it("should detect that dictionary is not empty", function()
			local isEmpty = parentModule.IsEmpty({ a = 10, b = 20, c = 30 })
			expect(isEmpty).to.equal(false)
		end)
	end)
	describe("JSON", function()
		it("should encode json", function()
			local encodeJSON = parentModule.EncodeJSON({ hello = "world" })
			expect(encodeJSON).to.equal("{\"hello\":\"world\"}")
		end)
		it("should decode json", function()
			local decodeJSON = parentModule.DecodeJSON("{\"hello\":\"world\"}")
			expect(decodeJSON).to.be.a("table")
			expect(decodeJSON.hello).to.equal("world")
		end)
	end)
end