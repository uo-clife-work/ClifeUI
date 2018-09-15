

ClfContnrSearch = {}


ClfContnrSearch.SearchText_org = nil
ClfContnrSearch.UpdateList_org = nil
ClfContnrSearch.Restart_org = nil


function ClfContnrSearch.initialize()

	local ClfContnrSearch = ClfContnrSearch
	local ContainerSearch = ContainerSearch

	-- Override functions
	if ( not ClfContnrSearch.SearchText_org ) then
		ClfContnrSearch.SearchText_org = ContainerSearch.SearchText
		ContainerSearch.SearchText = ClfContnrSearch.onSearchText
	end

	if ( not ClfContnrSearch.UpdateList_org ) then
		ClfContnrSearch.UpdateList_org = ContainerSearch.UpdateList
		ContainerSearch.UpdateList = ClfContnrSearch.onUpdateList
	end

	if ( not ClfContnrSearch.Restart_org ) then
		ClfContnrSearch.Restart_org = ContainerSearch.Restart
		ContainerSearch.Restart = ClfContnrSearch.onRestart
	end

end


function ClfContnrSearch.onSearchText( null, text )
	local textArr =  ClfUtil.explode( L"|", text )
	local wordCount = #textArr
	if ( wordCount > 1 ) then
		local CS_Patterns = ContainerSearch.Patterns
		local isInArray = ClfUtil.isInArray
		local lastWord
		for i = wordCount, 1, -1 do
			local word = textArr[ i ]
			if ( word ~= L"" and word ~= "" and not isInArray( word, CS_Patterns ) ) then
				if ( lastWord ) then
					table.insert( CS_Patterns, word )
				else
					lastWord = word
				end
			end
		end
		text = lastWord
	end

	ClfContnrSearch.SearchText_org( null, text )

	ClfContnrSearch.addPropText()
end


function ClfContnrSearch.onUpdateList( remove )
	ClfContnrSearch.UpdateList_org( remove )

	ClfContnrSearch.addPropText()
end


function ClfContnrSearch.onRestart()
	ClfContnrSearch.Restart_org()

	ClfContnrSearch.addPropText()
end


local defColor = { r = 255, g = 255, b = 255 }

function ClfContnrSearch.addPropText()
	local ClfContnrWin = ClfContnrWin
	if ( not ClfContnrWin.Enable ) then
		return nil
	end

	local colorTbl = ClfContnrWin.TxtColorsLight
	local hueTbl = ClfContnrWin.HueTbl

	local ContainerSearch_Slots = ContainerSearch.Slots
	local WindowData_ObjectInfo = WindowData.ObjectInfo

	local ClfContnrWin_getInterestPropObj = ClfContnrWin.getInterestPropObj
	local WindowGetId = WindowGetId
	local WindowSetDimensions = WindowSetDimensions
	local WindowClearAnchors = WindowClearAnchors
	local WindowAddAnchor = WindowAddAnchor
	local LabelGetText = LabelGetText
	local LabelSetText = LabelSetText
	local LabelSetFont = LabelSetFont
	local LabelSetTextColor = LabelSetTextColor
	local DynamicImageSetCustomShader = DynamicImageSetCustomShader
	local type = type
	local towstring = towstring
	local wSub = wstring.sub
	local wLen = wstring.len

	for j = 1, #ContainerSearch_Slots, 1 do
		local slot = ContainerSearch_Slots[ j ]
		if ( DoesWindowExist( slot ) ) then
			local objectId = WindowGetId( slot )
			local propObj = objectId and ClfContnrWin_getInterestPropObj( objectId, nil, nil )

			if ( propObj ) then
				local txt = propObj.text
				local objs = propObj and propObj.objs

				if ( objs and #objs > 0 ) then
					local tmpTxt = nil
					local txtLong = L""
					local usedKeys = {}

					for i = 1, #objs, 1 do
						local obj = objs[ i ]
						if ( type( obj ) == "table" ) then
							if ( not obj.propKey or not usedKeys[ obj.propKey ] ) then
								if ( obj.rawText ) then
									txtLong = txtLong .. obj.rawText .. L", "
								elseif ( obj.text ) then
									tmpTxt = obj.text
									if ( type( obj.text ) ~= "wstring" ) then
										tmpTxt = towstring( tmpTxt )
									end
									txtLong = txtLong .. tmpTxt .. L", "
								end
								if ( obj.propKey ) then
									usedKeys[ obj.propKey ] = true
								end
							end
						end
					end

					local txtLen = wLen( txtLong )

					if ( txtLen > 2 ) then
						txt = wSub( txtLong, 1, txtLen - 2 )
					end
				end

				if ( txt ) then
					local elmIcon = slot .. "Icon"
					local elmName = slot .. "Name"
					local orgStr = LabelGetText( elmName )
					local item = WindowData_ObjectInfo[ objectId ]
					if ( propObj.hue and item and item.objectType  ) then
						hue = hueTbl[ propObj.hue ]
						if ( hue ) then
							DynamicImageSetCustomShader( elmIcon, "UOSpriteUIShader", { hue, item.objectType } )
						end
					end
					orgStr = orgStr and orgStr .. L"\n" or L""

					LabelSetFont( elmName, "MyriadPro_13", 1 )
					WindowSetDimensions( elmName, 210, 35 )
					WindowClearAnchors( elmName )
					WindowAddAnchor( elmName, "topright", elmIcon, "topleft", 5, -4 )
					LabelSetText( elmName, orgStr .. txt )

					if ( propObj.color == "note" ) then
						propObj.color = nil
					end
					local color = propObj.color and colorTbl[ propObj.color ] or defColor
					LabelSetTextColor( elmName, color.r, color.g, color.b )
				end
			end
		end
	end

end



-- EOF
