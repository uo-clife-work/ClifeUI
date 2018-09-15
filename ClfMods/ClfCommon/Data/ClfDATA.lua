

ClfD = {}

ClfDataFuncs = {}

local PATH = "UserInterface/" .. SystemData.Settings.Interface.customUiName .. "/ClfMods/ClfCommon/Data/"
local CSV_PATH = PATH .. "csv/"

function ClfDataFuncs.initialize()
	ClfDataFuncs.initDatas()
end


function ClfDataFuncs.initDatas()

	local empty = ClfUtil.tableEmpty
	local loadCSVtoTable = ClfUtil.loadCSVtoTable

	local files = {
		{
			-- マジックプロパティのtId
			tableName = "MagicTids",
			file = "tid_magic.csv",
			keys = { "tId", "key", },
			option = {
				toStrKeys = { "key", },
				numOnlyKeys = { "tId", },
			},
		},
		{
			-- スキルグループのtId
			tableName = "SkillGroupTids",
			file = "tid_skillGroup.csv",
			keys = { "tId", "key", },
			option = {
				toStrKeys = { "key", },
				numOnlyKeys = { "tId", },
			},
		},
		{
			-- マジックプロパティとしてカウントしないプロパティのtId
			tableName = "NonMagicTids",
			file = "tid_nonMagic.csv",
			keys = { "tId", "key", },
			option = {
				toStrKeys = { "key", },
				numOnlyKeys = { "tId", },
			},
		},
		{
			-- スキル+プロパティの子要素として付随するスキル種類のtId
			tableName = "ChildPropTids",
			file = "tid_childProp.csv",
			keys = { "tId", "key", "parentKey", },
			option = {
				toStrKeys = { "key", "parentKey", },
				numOnlyKeys = { "tId", },
			},
		},
		{
			-- 武器の攻撃属性プロパティのtId
			tableName = "DamageTypeTids",
			file = "tid_damageType.csv",
			keys = { "tId", "key", },
			option = {
				toStrKeys = { "key", },
				numOnlyKeys = { "tId", },
			},
		},
		{
			-- 属性抵抗のtId ※リング、武器等に付く属性抵抗も同じtIDなので注意
			tableName = "RegistTypeTids",
			file = "tid_registType.csv",
			keys = { "tId", "key", "nqMax", },
			option = {
				toStrKeys = { "key", },
				numOnlyKeys = { "tId", "nqMax", },
			},
		},
		{
			-- （ユニークな）アイテム名用プロパティのtId
			tableName = "UniqueNameTids",
			file = "tid_uniquName.csv",
			keys = { "tId", "key", },
			option = {
				toStrKeys = { "key", },
				numOnlyKeys = { "tId", },
			},
		},
		{
			-- タリスマン名用プロパティのtId
			tableName = "TalisNameTids",
			file = "tid_talismanName.csv",
			keys = { "tId", "key", },
			option = {
				toStrKeys = { "key", },
				numOnlyKeys = { "tId", },
			},
		},
		{
			-- 特効プロパティのtId
			tableName = "SlayerTids",
			file = "tid_slayers.csv",
			keys = { "tId", "key", "subkey", "superSlayer", "opposite", },
			option = {
				toStrKeys = { "key", "subkey" },
				numOnlyKeys = { "tId", "opposite" },
				nilOrTrueKeys = { "superSlayer" },
			},
		},
		{
			-- objectType
			tableName = "ObjectTypes",
			file = "objectType.csv",
			keys = { "objectType", "typeName", "key", "hueId", },
			option = {
				toStrKeys = { "typeName", "key" },
				numOnlyKeys = { "objectType", "hueId", },
			},
		},
	}

	local dir = CSV_PATH
	for i = 1, #files do
		local obj = files[ i ]
		local tableName = obj.tableName
		if ( tableName and ( not ClfD[ tableName ] or empty( ClfD[ tableName ] ) ) ) then
			local file = obj.file and dir .. obj.file
			local data = loadCSVtoTable( file, obj.keys, obj.option )
			if ( not data ) then
				Debug.PrintToChat( L"ERROR: Failed to load " .. towstring( obj.file ) )
				data = {}
			end
			ClfD[ tableName ] = data
		end
	end

	Debug.PrintToChat( L"ClfDATA: initialize data complete" )
end

