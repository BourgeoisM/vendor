local _, Addon = ...;
local MODEL_KEY = {};
local MODEL_INDEX_KEY = {};
local INDEX_KEY = {};
local ListItem = {};

--[[===========================================================================
	| Clears all of the data for this list item, including clearing the 
	| anchors, and hiding the frame.
	========================================================================--]]
function ListItem:ResetAll()
	rawset(self, MODEL_KEY, nil);
	rawset(self, MODEL_INDEX_KEY, nil);
	rawset(self, INDEX_KEY, nil);
	self:ClearAllPoints();
	self:Hide();
end

--[[===========================================================================
	| Returns the data/model item this visual is using
	========================================================================--]]
function ListItem:GetModel()
	return rawget(self, MODEL_KEY);
end

--[[===========================================================================
	| Sets the mode for this item base, if the model has changed then
    | OnModelChanged is invoked allowing the item to update itself.
	========================================================================--]]
function ListItem:SetModel(model)
	local m = rawget(self, MODEL_KEY);
	if (m ~= model) then
		rawset(self, MODEL_KEY, model)
		local cb = self.OnModelChanged;
		if (type(cb) == "function") then
			xpcall(cb, CallErrorHandler, self, model);
		end
	end
end

--[[===========================================================================
	| Sets the model index (the index into the model collection)
	========================================================================--]]
function ListItem:SetModelIndex(modelIndex)
	rawset(self, MODEL_INDEX_KEY, modelIndex);
end

--[[===========================================================================
	| Retrieves the model index
	========================================================================--]]
function ListItem:GetModelIndex()
	return rawget(self, MODEL_INDEX_KEY);
end

--[[===========================================================================
	|Sets the item index (the position in the view)
	========================================================================--]]
function ListItem:SetItemIndex(index)
	rawset(self, INDEX_KEY, index);
end

--[[===========================================================================
	| Retrieves the item index for this item.
	========================================================================--]]
function ListItem:GetItemIndex()
	return rawget(self, INDEX_KEY) or -1;
end

--[[===========================================================================
	| Checks if this and the specified item have the samde model.
	========================================================================--]]
function ListItem:IsSameModel(other)
	return (rawget(self, MODEL_KEY) == rawget(other, MODEL_KEY));
end

--[[===========================================================================
	| Returns true of the item has the model specified.
	========================================================================--]]
function ListItem:HasModel(model)
	return (rawget(self, MODEL_KEY) == model);
end

--[[===========================================================================
	| Compares two items, if the item has a "Compare" functino it is invoked
	| otherwsie the indexs are compared.
	========================================================================--]]
function ListItem:CompareTo(other)
	if (type(self.Compare) == "function") then
		local success, result = xpcall(self.Compare, CallErrorHandler, self, other);
		if (success) then
			return result;
		end
	end

	return (rawget(self, MODEL_INDEX_KEY) or 0) < 
			(rawget(self, MODEL_INDEX_KKEY) or 0);
end

function ListItem:IsSelected()
	return (self.selected == true);
end

function ListItem:SetSelected(selected)
	if (self.selected ~= selected) then
		self.selected = selected;
		local cb = self.OnSelected;
		if (type(cb) == "function") then
			xpcall(cb, CallErrorHandler, self, selected);
		end
	end
end

Addon.Controls = Addon.Controls or {};
Addon.Controls.ListItem = {
	Attach = function(self, control)
		return Mixin(control, ListItem);
	end
};
