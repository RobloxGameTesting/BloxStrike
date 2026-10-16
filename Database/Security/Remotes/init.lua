local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Network = require(ReplicatedStorage.Database.Security.Network)
local DefinePacket = require(script:WaitForChild("DefinePacket"))
local struct = Network.Struct({
	_id = Network.String,
	Type = Network.String,
	Serial = Network.Optional(Network.Uint32),
	Name = Network.String,
	Skin = Network.String,
	Rarity = Network.Optional(Network.String),
	Float = Network.Optional(Network.Float32),
	StatTrack = Network.Unknown,
	IsTradeable = Network.Optional(Network.Bool),
	NameTag = Network.Unknown,
	OriginalOwner = Network.Optional(Network.String),
	Charm = Network.Unknown,
	Pattern = Network.Optional(Network.Uint16),
	Stickers = Network.Optional(Network.Array(Network.Struct({
		Sticker = Network.String,
		Position = Network.Struct({
			Rotation = Network.Float32,
			X = Network.Float32,
			Y = Network.Float32
		})
	}))),
	MetaData = Network.Optional(Network.Struct({
		LastTradeAt = Network.Optional(Network.Float64),
		CreatedAt = Network.Optional(Network.Float64),
		TradeHistory = Network.Optional(Network.Array(Network.String)),
		OriginalOwner = Network.Optional(Network.String),
		Owner = Network.Optional(Network.String),
		Origin = Network.Optional(Network.String),
		GlobalMarketPlaceListingReference = Network.Optional(Network.String)
	})),
	__v = Network.Optional(Network.Uint32)
})

local function DefineNamespace(childName, fn)
	if RunService:IsClient() then
		ReplicatedStorage:WaitForChild("NetworkRemotes"):WaitForChild(childName)
	end

	local v = fn()
	local v2 = {}

	for k, v3 in pairs(v) do
		if type(v3) == "function" then
			v2[k] = v3(childName, k)
		else
			v2[k] = v3
		end
	end

	return table.freeze(v2)
end

return table.freeze({
	Collaborations = DefineNamespace("Collaborations", function()
		return {
			ClaimExclusiveMedalReward = DefinePacket(Network.DefinePacket({
				Value = Network.Nothing
			}), {
				maximum_requests_per_second = 1
			}),
			RefreshMedalStatus = DefinePacket(Network.DefinePacket({ Value = Network.String }), {
				maximum_requests_per_second = 0.2
			}),
			MedalAutoClip = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					EventId = Network.String,
					EventName = Network.String,
					Duration = Network.Float32,
					CaptureDelayMs = Network.Optional(Network.Float32),
					ContextTags = Network.Optional(Network.Map(Network.String, Network.String))
				})
			}))
		}
	end),
	PlayerData = DefineNamespace("PlayerData", function()
		return {
			RetrieveAllPlayerData = DefinePacket(Network.DefinePacket({ Value = Network.Nothing })),
			PlayerDataEvent = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({ Player = Network.Instance, Data = Network.Unknown })
			})),
			PlayerDataChanged = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Data = Network.Map(Network.String, Network.Unknown),
					Player = Network.Instance
				})
			})),
			SubmitPin = DefinePacket(Network.DefinePacket({ Code = Network.String })),
			PinResult = DefinePacket(Network.DefinePacket({ Success = Network.Bool }))
		}
	end),
	Player = DefineNamespace("Player", function()
		return {
			UpdatePlayerSettings = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({ Path = Network.String, Value = Network.Unknown })
			}), { maximum_requests_per_second = 3 }),
			UpdateMobileButtons = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Layout = Network.Map(Network.String, Network.Unknown)
				})
			}), { maximum_requests_per_second = 1 }),
			SetViewmodelHand = DefinePacket(Network.DefinePacket({ Value = Network.Bool }), {
				maximum_requests_per_second = 10
			}),
			MarkShopVersionViewed = DefinePacket(Network.DefinePacket({ Value = Network.Nothing }), {
				maximum_requests_per_second = 1
			}),
			NewInventoryItemsSeen = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					ItemIds = Network.Array(Network.String),
					Dismissed = Network.Bool
				})
			}), { maximum_requests_per_second = 2 }),
			MarkTutorialPrompted = DefinePacket(Network.DefinePacket({ Value = Network.Nothing }), {
				maximum_requests_per_second = 1
			}),
			BlankRequest = DefinePacket(Network.DefinePacket({ Value = Network.Float64 }), {
				maximum_requests_per_second = 1
			}),
			ReportPlayerConnect = DefinePacket(Network.DefinePacket({ Value = Network.String }), {
				maximum_requests_per_second = 1
			}),
			SubmitPlayerReport = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					ReportedPlayer = Network.Instance,
					Reason = Network.String,
					Detail = Network.Optional(Network.String)
				})
			}), { maximum_requests_per_second = 1 }),
			SubmitUserPlatformAnalytics = DefinePacket(Network.DefinePacket({
				Value = Network.String
			}), {
				maximum_requests_per_second = 1
			}),
			PressedPlay = DefinePacket(Network.DefinePacket({ Value = Network.Nothing }), {
				maximum_requests_per_second = 1
			}),
			AFKTeleport = DefinePacket(Network.DefinePacket({ Value = Network.Nothing }), {
				maximum_requests_per_second = 1
			})
		}
	end),
	VoteKick = DefineNamespace("VoteKick", function()
		local function DefineVoteKickTallyPacket(maximum_requests_per_second: number)
			return DefinePacket(Network.DefinePacket({
				Value = Network.Struct({ Amount = Network.Uint8, Voter = Network.String })
			}), { maximum_requests_per_second = maximum_requests_per_second })
		end

		return {
			VoteNo = DefineVoteKickTallyPacket(1),
			VoteYes = DefineVoteKickTallyPacket(1),
			VoteNoUpdate = DefineVoteKickTallyPacket(0),
			VoteYesUpdate = DefineVoteKickTallyPacket(0),
			StartVote = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					TargetUserId = Network.String,
					VoterUserId = Network.String
				})
			}), { maximum_requests_per_second = 0 }),
			EndVote = DefinePacket(Network.DefinePacket({ Value = Network.Nothing }), {
				maximum_requests_per_second = 1
			}),
			CallVote = DefinePacket(Network.DefinePacket({ Value = Network.String }), {
				maximum_requests_per_second = 1
			})
		}
	end),
	Character = DefineNamespace("Character", function()
		return {
			CharacterDamaged = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					VictimUserId = Network.Float64,
					Headshot = Network.Optional(Network.Bool),
					Direction = Network.Optional(Network.Vec3),
					Melee = Network.Optional(Network.Bool)
				})
			})),
			CharacterDied = DefinePacket(Network.DefinePacket({ Value = Network.Nothing })),
			Action = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					UserId = Network.Float64,
					Generation = Network.Uint16,
					ActionId = Network.Uint8
				})
			}), { maximum_requests_per_second = 40 })
		}
	end),
	Sound = DefineNamespace("Sound", function()
		return {
			ReplicateSound = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Position = Network.Optional(Network.Vec3),
					Parent = Network.Optional(Network.Instance),
					Duration = Network.Optional(Network.String),
					Path = Network.Optional(Network.String),
					Class = Network.String,
					Name = Network.String
				})
			}), { maximum_requests_per_second = 25 }),
			StopSoundAtPosition = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({ Position = Network.Vec3, Radius = Network.Float32 })
			}))
		}
	end),
	Store = DefineNamespace("Store", function()
		return {
			ConsoleOpened = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					DeletedCaseIds = Network.Array(Network.String),
					CaseIdentifier = Network.String,
					CaseId = Network.String,
					RequestId = Network.Optional(Network.String),
					ConsoleOutcome = Network.Optional(Network.Unknown),
					ConsoleOutcomes = Network.Optional(Network.Array(Network.Unknown)),
					InventoryItems = Network.Array(Network.Unknown)
				})
			}), { maximum_requests_per_second = 1 }),
			CaseOpened = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					DeletedCaseIds = Network.Array(Network.String),
					CaseIdentifier = Network.String,
					CaseId = Network.String,
					RequestId = Network.Optional(Network.String),
					InventoryItems = Network.Array(struct)
				})
			}), { maximum_requests_per_second = 1 }),
			PurchaseTradeTokensProduct = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({ ProductName = Network.String })
			}), { maximum_requests_per_second = 1 }),
			PurchaseTradeTokensCase = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({ ProductName = Network.String, Quantity = Network.Uint8 })
			}), { maximum_requests_per_second = 1 }),
			PurchaseConsoleTradeTokens = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({ ProductName = Network.String, Quantity = Network.Uint8 })
			}), { maximum_requests_per_second = 1 }),
			CaseOpenDenied = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Reason = Network.Optional(Network.String),
					RequestId = Network.Optional(Network.String),
					RetryAfterMs = Network.Optional(Network.Float64)
				})
			}), { maximum_requests_per_second = 1 }),
			OpenCase = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					CaseIdentifiers = Network.Array(Network.String),
					OpenType = Network.String,
					CaseId = Network.String,
					RequestId = Network.Optional(Network.String)
				})
			}), { maximum_requests_per_second = 3 }),
			OpenConsole = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					CaseIdentifiers = Network.Array(Network.String),
					CaseId = Network.String,
					RequestId = Network.Optional(Network.String)
				})
			}), { maximum_requests_per_second = 1 }),
			TradeUpItems = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					ItemIds = Network.Array(Network.String),
					RequestId = Network.Optional(Network.String)
				})
			}), { maximum_requests_per_second = 1 }),
			TradeUpCompleted = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					DeletedItemIds = Network.Array(Network.String),
					RequestId = Network.Optional(Network.String),
					InventoryItem = struct
				})
			}), { maximum_requests_per_second = 1 }),
			TradeUpDenied = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Reason = Network.Optional(Network.String),
					RequestId = Network.Optional(Network.String)
				})
			}), { maximum_requests_per_second = 1 }),
			CaseOpenSequenceFinished = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({ CaseIdentifier = Network.String })
			}), { maximum_requests_per_second = 3 }),
			NewInventoryItem = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Items = Network.Array(struct),
					Player = Network.String,
					DeletedItemIds = Network.Optional(Network.Array(Network.String))
				})
			}), { maximum_requests_per_second = 8 }),
			GiftCase = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					RecipientUserId = Network.String,
					CaseId = Network.String,
					Amount = Network.Uint8
				})
			}), { maximum_requests_per_second = 1 }),
			PurchaseCase = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({ CaseId = Network.String, Amount = Network.Uint8 })
			}), { maximum_requests_per_second = 3 }),
			OpenedShop = DefinePacket(Network.DefinePacket({ Value = Network.Struct({}) }), {
				maximum_requests_per_second = 1
			}),
			CreateGift = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					RecipientUserId = Network.String,
					ProductName = Network.String,
					ProductType = Network.String
				})
			}), { maximum_requests_per_second = 1 })
		}
	end),
	Spectate = DefineNamespace("Spectate", function()
		return {
			UpdateCameraCFrame = DefinePacket(Network.DefinePacket({
				ReliabilityType = "Unreliable",
				Value = Network.Struct({ CameraCFrame = Network.CFrame, UserId = Network.Float64 })
			}), { maximum_requests_per_second = 60 }),
			SetSpectatePerspective = DefinePacket(Network.DefinePacket({ Value = Network.String })),
			SpectatePlayer = DefinePacket(Network.DefinePacket({ Value = Network.String })),
			StartSpectating = DefinePacket(Network.DefinePacket({ Value = Network.Nothing })),
			StopSpectating = DefinePacket(Network.DefinePacket({ Value = Network.Nothing }))
		}
	end),
	Dashboard = DefineNamespace("Dashboard", function()
		return {
			MissionCompleted = DefinePacket(Network.DefinePacket({ Value = Network.String }), {
				maximum_requests_per_second = 1
			}),
			RedeemCode = DefinePacket(Network.DefinePacket({ Value = Network.String }), {
				maximum_requests_per_second = 1
			}),
			RedeemPromotionalReward = DefinePacket(Network.DefinePacket({ Value = Network.String }), {
				maximum_requests_per_second = 1
			}),
			ClaimStarReward = DefinePacket(Network.DefinePacket({ Value = Network.Float64 }), {
				maximum_requests_per_second = 10
			})
		}
	end),
	Map = DefineNamespace("Map", function()
		return {
			SubmitMapVote = DefinePacket(Network.DefinePacket({ Value = Network.String })),
			StartMapVote = DefinePacket(Network.DefinePacket({
				Value = Network.Array(Network.String)
			})),
			UpdateMapVote = DefinePacket(Network.DefinePacket({
				Value = Network.Map(Network.String, Network.Uint8)
			})),
			EndMapVote = DefinePacket(Network.DefinePacket({ Value = Network.String })),
			RequestMapVote = DefinePacket(Network.DefinePacket({ Value = Network.Nothing }))
		}
	end),
	Match = DefineNamespace("Match", function()
		return {
			EndScreen = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					WinningTeam = Network.String,
					CTScore = Network.Uint16,
					TScore = Network.Uint16,
					Players = Network.Map(Network.String, Network.Struct({
						Team = Network.String,
						ADR = Network.Float32,
						Kills = Network.Uint16,
						Deaths = Network.Uint16,
						Assists = Network.Uint16,
						Score = Network.Int16,
						Headshots = Network.Uint16,
						Accolade = Network.String,
						Name = Network.Optional(Network.String),
						AvatarUserId = Network.Optional(Network.Float64),
						ExperienceEarned = Network.Optional(Network.Uint32),
						Weapon = Network.Optional(Network.Struct({
							Name = Network.String,
							Skin = Network.String,
							Float = Network.Float32,
							StatTrack = Network.Unknown,
							NameTag = Network.Unknown
						})),
						Gloves = Network.Optional(Network.Struct({
							Name = Network.String,
							Skin = Network.String,
							Float = Network.Float32
						})),
						LevelRewards = Network.Optional(Network.Array(Network.Struct({
							type = Network.String,
							amount = Network.Optional(Network.Uint32),
							inventoryItem = Network.Optional(Network.Struct({
								_id = Network.String,
								Name = Network.String,
								Skin = Network.Optional(Network.String),
								Rarity = Network.String,
								Type = Network.String,
								Float = Network.Optional(Network.Float32),
								Serial = Network.Optional(Network.Uint32),
								Pattern = Network.Optional(Network.Uint16),
								StatTrack = Network.Unknown,
								NameTag = Network.Unknown,
								Charm = Network.Unknown,
								IsTradeable = Network.Optional(Network.Bool),
								Stickers = Network.Optional(Network.Unknown),
								MetaData = Network.Optional(Network.Unknown),
								__v = Network.Optional(Network.Uint32)
							}))
						})))
					})),
					ShowAccolades = Network.Optional(Network.Bool),
					ShowProgression = Network.Optional(Network.Bool),
					SequenceDuration = Network.Optional(Network.Float32),
					ReturnToMenu = Network.Optional(Network.Bool),
					Halftime = Network.Optional(Network.Bool),
					Locked = Network.Optional(Network.Bool)
				})
			}))
		}
	end),
	Inventory = DefineNamespace("Inventory", function()
		return {
			RemoveInventoryItem = DefinePacket(Network.DefinePacket({ Value = Network.String })),
			NewInventoryItem = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Generation = Network.Uint16,
					customProperties = Network.Optional(Network.Map(Network.String, Network.Unknown)),
					OriginalOwner = Network.Optional(Network.String),
					StatTrack = Network.Unknown,
					NameTag = Network.Unknown,
					Charm = Network.Unknown,
					Float = Network.Float32,
					identifier = Network.String,
					shouldEquip = Network.Optional(Network.Bool),
					isPurchase = Network.Optional(Network.Bool),
					weapon = Network.String,
					skin = Network.String,
					slot = Network.Uint8,
					_id = Network.String,
					Stickers = Network.Array(Network.Struct({
						Sticker = Network.String,
						Position = Network.Struct({
							X = Network.Float32,
							Y = Network.Float32,
							Rotation = Network.Float32
						})
					}))
				})
			})),
			UpdateStatTrack = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Player = Network.Instance,
					Identifier = Network.String,
					StatTrack = Network.Uint32
				})
			})),
			CleanupGameLoadout = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({ Generation = Network.Uint16 })
			})),
			CreateGameLoadout = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Generation = Network.Uint16,
					Inventory = Network.Array(Network.Struct({
						_items = Network.Array(Network.Struct({ Identifier = Network.String })),
						_settings = Network.Struct({
							_strict_slot_space = Network.Uint8,
							_strict_type = Network.String
						})
					}))
				})
			})),
			RequestSpectatedPlayerInventory = DefinePacket(Network.DefinePacket({
				Value = Network.Instance
			})),
			SpectatedPlayerInventory = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Player = Network.Instance,
					Inventory = Network.Array(Network.Struct({
						_items = Network.Array(Network.Struct({
							Identifier = Network.String,
							Name = Network.String,
							Skin = Network.Optional(Network.String),
							Slot = Network.Uint8,
							Properties = Network.Struct({
								Class = Network.String,
								Icon = Network.String,
								Slot = Network.String
							})
						})),
						_settings = Network.Struct({
							_strict_slot_space = Network.Uint8,
							_strict_type = Network.String
						})
					})),
					EquippedSlot = Network.Uint8,
					EquippedSlotSpace = Network.Uint8
				})
			})),
			WeaponEquipResolved = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					RequestId = Network.Uint32,
					Identifier = Network.Optional(Network.String)
				})
			})),
			ReturnBuyMenuPurchase = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({ Identifier = Network.String, Equipment = Network.Bool })
			})),
			BuyMenuPurchase = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Name = Network.String,
					Equipment = Network.Bool,
					Path = Network.String
				})
			}), { maximum_requests_per_second = 3 }),
			PickupWeapon = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({ Identity = Network.String, AllowAutoEquip = Network.Bool })
			}), { maximum_requests_per_second = 7 }),
			DropWeapon = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Identifier = Network.String,
					Direction = Network.Vec3,
					CharacterVelocity = Network.Optional(Network.Vec3)
				})
			}), { maximum_requests_per_second = 5 }),
			UpdateScopeIncrement = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Increment = Network.Uint8,
					SoundName = Network.Optional(Network.String)
				})
			}), { maximum_requests_per_second = 10 }),
			UpdateWeaponSuppressor = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({ Identifier = Network.String, State = Network.Bool })
			})),
			UpdateWeaponCharm = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					WeaponId = Network.String,
					CharmId = Network.String,
					Position = Network.String
				})
			})),
			RemoveWeaponCharm = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({ WeaponId = Network.String })
			})),
			ReloadWeapon = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Identifier = Network.String,
					Rounds = Network.Uint16,
					Capacity = Network.Uint16
				})
			})),
			RefillAmmo = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Identifier = Network.String,
					Rounds = Network.Uint16,
					Capacity = Network.Uint16
				})
			})),
			ShootWeapon = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					ShootingHand = Network.String,
					Identifier = Network.String,
					Seq = Network.Uint32,
					IsSniperScoped = Network.Bool,
					Bullets = Network.Array(Network.Struct({
						Direction = Network.Vec3,
						Origin = Network.Vec3
					})),
					ViewTick = Network.Optional(Network.Float64)
				})
			}), { maximum_requests_per_second = 20 }),
			CreateMagazine = DefinePacket(Network.DefinePacket({ Value = Network.String }), {
				maximum_requests_per_second = 1
			}),
			EquipLoadoutSkin = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Type = Network.String,
					Slot = Network.Uint8,
					Team = Network.String,
					Identifier = Network.String
				})
			}), { maximum_requests_per_second = 5 }),
			SwapLoadoutSkins = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Type = Network.String,
					SlotOne = Network.Uint8,
					SlotTwo = Network.Uint8,
					Team = Network.String
				})
			}), { maximum_requests_per_second = 5 }),
			EquipSpecialItem = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Path = Network.String,
					Team = Network.String,
					Identifier = Network.String
				})
			}), { maximum_requests_per_second = 5 }),
			LoadoutResponse = DefinePacket(Network.DefinePacket({ Value = Network.Bool }))
		}
	end),
	Projectile = DefineNamespace("Projectile", function()
		return {
			Spawn = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Id = Network.String,
					Weapon = Network.String,
					Skin = Network.String,
					Float = Network.Float32,
					StatTrack = Network.Unknown,
					NameTag = Network.Unknown,
					Charm = Network.Unknown,
					Stickers = Network.Array(Network.Struct({
						Sticker = Network.String,
						Position = Network.Struct({
							X = Network.Float32,
							Y = Network.Float32,
							Rotation = Network.Float32
						})
					})),
					State = Network.Struct({
						Position = Network.Vec3,
						Velocity = Network.Vec3,
						StartTime = Network.Optional(Network.Float64),
						IsJumpThrow = Network.Bool
					}),
					Physics = Network.Struct({
						Gravity = Network.Vec3,
						Drag = Network.Float32,
						Restitution = Network.Float32,
						Radius = Network.Float32,
						MaxBounces = Network.Uint8,
						FuseTime = Network.Float32,
						Step = Network.Float32,
						RestVelocityThreshold = Network.Float32,
						CollisionGroup = Network.String
					})
				})
			})),
			Resolve = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Id = Network.String,
					Grenade = Network.String,
					Position = Network.Vec3,
					Normal = Network.Vec3,
					Reason = Network.String
				})
			})),
			Bounce = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Id = Network.String,
					BounceIndex = Network.Uint8,
					Position = Network.Vec3,
					Velocity = Network.Vec3,
					Normal = Network.Vec3,
					Timestamp = Network.Float64
				})
			}))
		}
	end),
	VFX = DefineNamespace("VFX", function()
		return {
			ReplicateFinisher = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Skin = Network.Optional(Network.String),
					DirectionMultiplier = Network.Float32,
					Generation = Network.Uint16,
					Position = Network.Vec3,
					Velocity = Network.Vec3,
					LookYaw = Network.Float32,
					Finisher = Network.String,
					Direction = Network.Vec3,
					Weapon = Network.String,
					Killer = Network.Float64,
					Victim = Network.Float64,
					Part = Network.String
				})
			}), { maximum_requests_per_second = 5 }),
			CreateCharacterMuzzleFlash = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Suppressor = Network.Optional(Network.String),
					ShootingHand = Network.String,
					UserId = Network.Float64,
					Generation = Network.Uint16,
					WeaponName = Network.String
				})
			}), { maximum_requests_per_second = 25 }),
			CreateBloodSplatter = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Position = Network.Vec3,
					Direction = Network.Vec3,
					AttackerUserId = Network.Optional(Network.String)
				})
			}), { maximum_requests_per_second = 0 }),
			CreateImpact = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Instance = Network.Optional(Network.Instance),
					Material = Network.String,
					Position = Network.Vec3,
					Normal = Network.Vec3,
					Exit = Network.Bool,
					Ricochet = Network.Bool,
					AttackerUserId = Network.Optional(Network.String),
					ShotSeq = Network.Optional(Network.Uint32),
					VictimUserId = Network.Optional(Network.Float64),
					HitPartName = Network.Optional(Network.String),
					IsWallbang = Network.Optional(Network.Bool),
					WasHelmetHeadshot = Network.Optional(Network.Bool),
					SuppressVisuals = Network.Optional(Network.Bool),
					SuppressSound = Network.Optional(Network.Bool)
				})
			}), { maximum_requests_per_second = 25 }),
			CreateMarker = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Instance = Network.Instance,
					Type = Network.String,
					Position = Network.Vec3,
					Normal = Network.Vec3
				})
			}), { maximum_requests_per_second = 25 }),
			CreateTracer = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Distance = Network.Float32,
					Origin = Network.Vec3,
					Target = Network.Vec3
				})
			}), { maximum_requests_per_second = 25 }),
			CleanupDebris = DefinePacket(Network.DefinePacket({ Value = Network.Nothing })),
			BreakGlass = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Instance = Network.Instance,
					Position = Network.Vec3,
					Direction = Network.Vec3
				})
			}), { maximum_requests_per_second = 25 }),
			CreateVoxelSmoke = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					SmokeId = Network.String,
					Duration = Network.Float32,
					DeployTime = Network.Float32,
					Voxels = Network.Array(Network.Struct({
						Position = Network.Vec3,
						Size = Network.Float32
					})),
					Team = Network.Optional(Network.String)
				})
			})),
			DestroyVoxelSmoke = DefinePacket(Network.DefinePacket({ Value = Network.String })),
			DisruptVoxelSmoke = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Position = Network.Vec3,
					Radius = Network.Float32,
					Duration = Network.Float32
				})
			})),
			CreateVoxelFire = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					FireId = Network.String,
					Duration = Network.Float32,
					Position = Network.Vec3,
					Voxels = Network.Array(Network.Struct({
						Position = Network.Vec3,
						SizeX = Network.Float32,
						SizeZ = Network.Float32,
						Normal = Network.Vec3
					}))
				})
			})),
			DestroyVoxelFire = DefinePacket(Network.DefinePacket({ Value = Network.String })),
			UpdateVoxelFire = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					FireId = Network.String,
					Voxels = Network.Array(Network.Struct({
						Position = Network.Vec3,
						SizeX = Network.Float32,
						SizeZ = Network.Float32,
						Normal = Network.Vec3
					}))
				})
			})),
			FlashPlayer = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Position = Network.Vec3,
					AttackerUserId = Network.Optional(Network.String),
					Duration = Network.Optional(Network.Float32)
				})
			}))
		}
	end),
	C4 = DefineNamespace("C4", function()
		return {
			Defused = DefinePacket(Network.DefinePacket({ Value = Network.Nothing })),
			StartDefuse = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({ SessionId = Network.Uint32 })
			})),
			CancelDefuse = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({ SessionId = Network.Uint32 })
			})),
			Planted = DefinePacket(Network.DefinePacket({ Value = Network.String })),
			Start = DefinePacket(Network.DefinePacket({ Value = Network.String })),
			Cancel = DefinePacket(Network.DefinePacket({ Value = Network.String })),
			ForceCancel = DefinePacket(Network.DefinePacket({ Value = Network.Nothing }))
		}
	end),
	Hostage = DefineNamespace("Hostage", function()
		return {
			StartRescue = DefinePacket(Network.DefinePacket({ Value = Network.Nothing })),
			CancelRescue = DefinePacket(Network.DefinePacket({ Value = Network.Nothing })),
			PickedUp = DefinePacket(Network.DefinePacket({ Value = Network.Nothing }))
		}
	end),
	BreakableDoor = DefineNamespace("BreakableDoor", function()
		return {
			Use = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Model = Network.Instance,
					ServerTick = Network.Optional(Network.Uint32),
					TargetAngle = Network.Optional(Network.Float32),
					RequestId = Network.Optional(Network.Uint32)
				})
			}), { maximum_requests_per_second = 10 }),
			Resolved = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Model = Network.Instance,
					RequestId = Network.Uint32,
					Accepted = Network.Bool
				})
			}))
		}
	end),
	Melee = DefineNamespace("Melee", function()
		return {
			MeleeAttack = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Direction = Network.Vec3,
					Material = Network.String,
					Distance = Network.Float32,
					Instance = Network.Optional(Network.Instance),
					VictimUserId = Network.Optional(Network.Float64),
					HitPartName = Network.Optional(Network.String),
					Position = Network.Vec3,
					Normal = Network.Vec3,
					MeleeAttack = Network.String,
					Identifier = Network.String
				})
			}), { maximum_requests_per_second = 5 })
		}
	end),
	Chat = DefineNamespace("Chat", function()
		return {
			ServerChat = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					displayName = Network.String,
					team = Network.String,
					message = Network.String,
					alive = Network.Bool,
					role = Network.Uint8,
					verified = Network.Bool
				})
			})),
			ServerTeamChat = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					displayName = Network.String,
					team = Network.String,
					message = Network.String,
					alive = Network.Bool,
					role = Network.Uint8,
					verified = Network.Bool
				})
			})),
			ChatTeamJoin = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({ name = Network.String, team = Network.String })
			})),
			ChatPlayerKilled = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Killer = Network.String,
					Weapon = Network.String,
					Points = Network.Optional(Network.Uint8)
				})
			})),
			ChatMoneyReward = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					weaponName = Network.Optional(Network.String),
					amount = Network.String,
					source = Network.String
				})
			})),
			ChatCaseOpened = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					displayName = Network.String,
					team = Network.String,
					weaponName = Network.String,
					skinName = Network.String,
					rarity = Network.String,
					statTrak = Network.Bool
				})
			})),
			ChatTradeUp = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					displayName = Network.String,
					team = Network.String,
					weaponName = Network.String,
					skinName = Network.String,
					rarity = Network.String,
					statTrak = Network.Bool
				})
			})),
			ChatPlayerLeave = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({ name = Network.String })
			})),
			ChatPlayerBanned = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({ name = Network.String })
			})),
			ChatSystemMessage = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({ message = Network.String })
			})),
			ChatTeamDamage = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					messageType = Network.String,
					displayName = Network.String,
					team = Network.String
				})
			})),
			ChatGrenadeThrow = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					displayName = Network.String,
					grenadeName = Network.String,
					team = Network.String
				})
			})),
			ChatDefuseStart = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					displayName = Network.String,
					team = Network.String,
					site = Network.String
				})
			})),
			ClientChat = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({ Text = Network.String, Mode = Network.Uint8 })
			}), { maximum_requests_per_second = 5 })
		}
	end),
	UI = DefineNamespace("UI", function()
		return {
			UpdateCreatorCode = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({ Text = Network.String, Type = Network.String })
			})),
			EquipCreatorCode = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({ CreatorCode = Network.String })
			}), { maximum_requests_per_second = 1 }),
			CreateMenuNotification = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					notificationType = Network.String,
					text = Network.String,
					skipWhenMenuClosed = Network.Optional(Network.Bool)
				})
			})),
			RoundWinner = DefinePacket(Network.DefinePacket({ Value = Network.String })),
			TeammateGrenades = DefinePacket(Network.DefinePacket({
				Value = Network.Array(Network.Struct({
					userId = Network.String,
					grenades = Network.Array(Network.String)
				}))
			})),
			RoundDamageMatrix = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					outgoing = Network.Map(Network.String, Network.Array(Network.Float32)),
					incoming = Network.Map(Network.String, Network.Array(Network.Float32))
				})
			})),
			RoundMVP = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					PlayerName = Network.String,
					Team = Network.String,
					Reason = Network.String
				})
			})),
			UIPlayerKilled = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Assistor = Network.Optional(Network.String),
					Float = Network.Optional(Network.Float32),
					Skin = Network.Optional(Network.String),
					Killer = Network.String,
					Victim = Network.String,
					Weapon = Network.String,
					Headshot = Network.Bool,
					NoScope = Network.Optional(Network.Bool),
					Smoke = Network.Optional(Network.Bool),
					Wallbang = Network.Optional(Network.Bool),
					Blind = Network.Optional(Network.Bool),
					Jump = Network.Optional(Network.Bool),
					FlashAssist = Network.Optional(Network.Bool),
					DeathPosition = Network.Optional(Network.Vec3)
				})
			})),
			ShowNotification = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					timeLength = Network.Float32,
					message = Network.String,
					header = Network.String
				})
			})),
			CreateDamageIndicator = DefinePacket(Network.DefinePacket({ Value = Network.Vec3 })),
			ShowDeathCard = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					KillerName = Network.String,
					KillerTeam = Network.String,
					Weapon = Network.String,
					Headshot = Network.Bool
				})
			}))
		}
	end),
	Ping = DefineNamespace("Ping", function()
		return {
			CreatePlayerPositionPing = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					WeaponIdentity = Network.Optional(Network.String),
					WeaponName = Network.Optional(Network.String),
					WeaponSkin = Network.Optional(Network.String),
					Position = Network.Vec3,
					IsDanger = Network.Bool
				})
			}), { maximum_requests_per_second = 2 })
		}
	end),
	TeamSelection = DefineNamespace("TeamSelection", function()
		return {
			SelectTeam = DefinePacket(Network.DefinePacket({ Value = Network.String }), {
				maximum_requests_per_second = 1
			})
		}
	end),
	Tutorial = DefineNamespace("Tutorial", function()
		return {
			ClientEvent = DefinePacket(Network.DefinePacket({ Value = Network.String }), {
				maximum_requests_per_second = 10
			})
		}
	end),
	Modes = DefineNamespace("Modes", function()
		return {
			SelectGamemode = DefinePacket(Network.DefinePacket({ Value = Network.String }), {
				maximum_requests_per_second = 1
			}),
			FetchPlayerCounts = DefinePacket(Network.DefinePacket({ Value = Network.Nothing }), {
				maximum_requests_per_second = 1
			}),
			SendPlayerCounts = DefinePacket(Network.DefinePacket({ Modes = {} }), {
				maximum_requests_per_second = 1
			}),
			FetchServers = DefinePacket(Network.DefinePacket({ Query = {} }), {
				maximum_requests_per_second = 1
			})
		}
	end),
	Hints = DefineNamespace("Hints", function()
		return {
			BombSiteEntered = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({ site = Network.String, action = Network.String })
			})),
			BombSiteExited = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({ site = Network.String, action = Network.String })
			})),
			ClearHint = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({ hintType = Network.String })
			}))
		}
	end),
	VIP = DefineNamespace("VIP", function()
		return {
			SetSetting = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({ Key = Network.String, Value = Network.Unknown })
			}), { maximum_requests_per_second = 5 }),
			ExecuteAction = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					Action = Network.String,
					Params = Network.Optional(Network.Unknown)
				})
			}), { maximum_requests_per_second = 2 }),
			SyncState = DefinePacket(Network.DefinePacket({
				Value = Network.Map(Network.String, Network.Unknown)
			})),
			RequestData = DefinePacket(Network.DefinePacket({ Value = Network.String }), {
				maximum_requests_per_second = 2
			}),
			DataResponse = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({ Type = Network.String, Data = Network.Unknown })
			}))
		}
	end),
	GlobalMarketplace = DefineNamespace("GlobalMarketplace", function()
		local function DefineMarketplacePacket(p, maximum_requests_per_second: number?)
			return DefinePacket(Network.DefinePacket({ Value = p }), {
				maximum_requests_per_second = maximum_requests_per_second
			})
		end

		return {
			SearchMarket = DefineMarketplacePacket(Network.Unknown, 4),
			RequestProfileInfo = DefineMarketplacePacket(Network.Float64, 1),
			DelistItem = DefineMarketplacePacket(Network.String, 2),
			PurchaseItem = DefineMarketplacePacket(Network.Unknown, 2),
			ListItem = DefineMarketplacePacket(Network.Unknown, 1),
			FetchRAP = DefineMarketplacePacket(Network.String, 2),
			FetchedRAP = DefineMarketplacePacket(Network.Unknown),
			NewItem = DefineMarketplacePacket(Network.Unknown),
			PurchaseItemResult = DefineMarketplacePacket(Network.Unknown),
			SearchMarketResults = DefineMarketplacePacket(Network.Struct({
				Listings = Network.Array(Network.Unknown),
				TotalPages = Network.Optional(Network.Float64),
				OnCooldown = Network.Optional(Network.Bool)
			})),
			ClearListing = DefineMarketplacePacket(Network.String),
			ListItemResult = DefineMarketplacePacket(Network.Unknown),
			RefreshInventory = DefineMarketplacePacket(Network.Nothing),
			ProfileInfo = DefineMarketplacePacket(Network.Unknown),
			PurchasedItem = DefineMarketplacePacket(Network.String),
			EndLoad = DefineMarketplacePacket(Network.Nothing)
		}
	end),
	ServerBrowser = DefineNamespace("ServerBrowser", function()
		return {
			Teleport = DefinePacket(Network.DefinePacket({ Value = Network.String }), {
				maximum_requests_per_second = 1
			})
		}
	end),
	Entity = DefineNamespace("Entity", function()
		return {
			InteractWithEntity = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({ EntityId = Network.String, Action = Network.String })
			}), { maximum_requests_per_second = 5 }),
			CreateEntity = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					EntityPosition = Network.Vec3,
					EntityName = Network.String,
					EntityId = Network.String
				})
			}), { maximum_requests_per_second = 50 }),
			DestroyEntity = DefinePacket(Network.DefinePacket({
				Value = Network.Struct({
					EntityId = Network.String,
					ClaimedBy = Network.Optional(Network.Float64)
				})
			}), { maximum_requests_per_second = 50 })
		}
	end),
	Career = DefineNamespace("Career", function()
		return {
			RequestStatistics = DefinePacket(Network.DefinePacket({ Value = Network.Nothing }), {
				maximum_requests_per_second = 1
			}),
			Statistics = DefinePacket(Network.DefinePacket({ Value = Network.Unknown })),
			RequestMatchDetails = DefinePacket(Network.DefinePacket({ Value = Network.String }), {
				maximum_requests_per_second = 4
			}),
			MatchDetails = DefinePacket(Network.DefinePacket({ Value = Network.Unknown }))
		}
	end),
	BlackMarketDealer = DefineNamespace("BlackMarketDealer", function()
		local function DefineDealerPacket(p, maximum_requests_per_second: number?)
			return DefinePacket(Network.DefinePacket({ Value = p }), {
				maximum_requests_per_second = maximum_requests_per_second
			})
		end

		return {
			RequestDeal = DefineDealerPacket(Network.Nothing, 1),
			BuyCard = DefineDealerPacket(Network.String, 2),
			DealData = DefineDealerPacket(Network.Unknown),
			BuyCardResult = DefineDealerPacket(Network.Unknown)
		}
	end)
})