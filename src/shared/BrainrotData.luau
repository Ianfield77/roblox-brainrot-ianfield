-- Brainrot Bazaar: the whole brainrot cast, rarities and mutations.
-- One source of truth: the server spawns from this, the client lists it in the Index.
-- Every character here is original, invented for this game.

local BrainrotData = {}

BrainrotData.RARITIES = {
	{ name = "Common", color = Color3.fromRGB(150, 170, 140), weight = 45, rushWeight = 30 },
	{ name = "Rare", color = Color3.fromRGB(80, 140, 255), weight = 28, rushWeight = 30 },
	{ name = "Epic", color = Color3.fromRGB(170, 90, 230), weight = 15, rushWeight = 20 },
	{ name = "Legendary", color = Color3.fromRGB(255, 150, 40), weight = 8, rushWeight = 12 },
	{ name = "Mythic", color = Color3.fromRGB(255, 80, 180), weight = 3, rushWeight = 5 },
	{ name = "Godly", color = Color3.fromRGB(255, 215, 0), weight = 1, rushWeight = 3 },
}

BrainrotData.CHARACTERS = {
	{ id = "kucing_nasi", name = "Kucing Nasi Goreng", rarity = "Common", rate = 5, blurb = "Meows in fried rice. Smells delicious." },
	{ id = "ayam_disco", name = "Ayam Disco", rarity = "Common", rate = 9, blurb = "A chicken that never stops dancing." },
	{ id = "bebek_kopi", name = "Bebek Es Kopi", rarity = "Rare", rate = 18, blurb = "A duck fuelled by iced coffee." },
	{ id = "kambing_skate", name = "Kambing Skateboard", rarity = "Rare", rate = 32, blurb = "A goat that ollies over traffic." },
	{ id = "ikan_turbo", name = "Ikan Terbang Turbo", rarity = "Epic", rate = 60, blurb = "A fish with a jet engine. It flies." },
	{ id = "gajah_balon", name = "Gajah Balon Udara", rarity = "Epic", rate = 95, blurb = "An elephant that floats away sometimes." },
	{ id = "naga_mie", name = "Naga Mie Pedas", rarity = "Legendary", rate = 160, blurb = "A noodle dragon. Very spicy. Very rich." },
	{ id = "raja_durian", name = "Raja Durian Emas", rarity = "Legendary", rate = 260, blurb = "The durian king. Smells like money." },
	{ id = "unicorn_soto", name = "Unicorn Soto Ayam", rarity = "Mythic", rate = 420, blurb = "A unicorn that serves chicken soup." },
	{ id = "dewa_mie", name = "Dewa Mie Raksasa", rarity = "Mythic", rate = 700, blurb = "The giant noodle god. Bow down." },
	{ id = "kapibara_kosmik", name = "Kapibara Kosmik", rarity = "Godly", rate = 1200, blurb = "A capybara from another galaxy. Chill." },
	{ id = "sultan_sate", name = "Sultan Sate Galaksi", rarity = "Godly", rate = 2000, blurb = "The satay sultan of the whole galaxy." },
}

BrainrotData.MUTATIONS = {
	{ name = "Normal", mult = 1, weight = 70, color = nil },
	{ name = "Golden", mult = 2, weight = 15, color = Color3.fromRGB(255, 215, 0) },
	{ name = "Diamond", mult = 3, weight = 10, color = Color3.fromRGB(120, 220, 255) },
	{ name = "Rainbow", mult = 5, weight = 5, color = Color3.fromRGB(255, 120, 220) },
}

function BrainrotData.getCharacter(id)
	for _, char in ipairs(BrainrotData.CHARACTERS) do
		if char.id == id then
			return char
		end
	end
	return nil
end

function BrainrotData.getRarity(name)
	for _, rarity in ipairs(BrainrotData.RARITIES) do
		if rarity.name == name then
			return rarity
		end
	end
	return BrainrotData.RARITIES[1]
end

function BrainrotData.getMutation(name)
	for _, mutation in ipairs(BrainrotData.MUTATIONS) do
		if mutation.name == name then
			return mutation
		end
	end
	return BrainrotData.MUTATIONS[1]
end

-- A brainrot costs ten seconds of its own income. Mutations multiply both.
function BrainrotData.costFor(char, mutationName)
	local mutation = BrainrotData.getMutation(mutationName)
	return char.rate * 10 * mutation.mult
end

function BrainrotData.rateFor(char, mutationName)
	local mutation = BrainrotData.getMutation(mutationName)
	return char.rate * mutation.mult
end

-- Weighted rarity roll. During a rush the odds tilt toward rarer spawns.
function BrainrotData.rollRarity(rush)
	local total = 0
	for _, rarity in ipairs(BrainrotData.RARITIES) do
		total += if rush then rarity.rushWeight else rarity.weight
	end
	local roll = math.random() * total
	local acc = 0
	for _, rarity in ipairs(BrainrotData.RARITIES) do
		acc += if rush then rarity.rushWeight else rarity.weight
		if roll <= acc then
			return rarity.name
		end
	end
	return "Common"
end

function BrainrotData.rollMutation()
	local total = 0
	for _, mutation in ipairs(BrainrotData.MUTATIONS) do
		total += mutation.weight
	end
	local roll = math.random() * total
	local acc = 0
	for _, mutation in ipairs(BrainrotData.MUTATIONS) do
		acc += mutation.weight
		if roll <= acc then
			return mutation.name
		end
	end
	return "Normal"
end

-- Pick a random character of the given rarity.
function BrainrotData.randomCharacterOfRarity(rarityName)
	local pool = {}
	for _, char in ipairs(BrainrotData.CHARACTERS) do
		if char.rarity == rarityName then
			table.insert(pool, char)
		end
	end
	if #pool == 0 then
		return BrainrotData.CHARACTERS[1]
	end
	return pool[math.random(#pool)]
end

-- Money with thousands separators, "$1,234" style.
function BrainrotData.formatMoney(amount)
	local n = math.floor(amount + 0.5)
	local s = tostring(n)
	local out = ""
	while #s > 3 do
		out = "," .. string.sub(s, -3) .. out
		s = string.sub(s, 1, -4)
	end
	return "$" .. s .. out
end

return BrainrotData
