LV_SetWidth(WidthList)
{
	WidthList := RegExReplace(WidthList, "\D+", "#")
	WidthList := Trim(WidthList, "#")
	loop, parse, WidthList, #
		LV_ModifyCol(A_Index, A_LoopField)
}

LV_CenterRows(Rows = "")
{
	Loop, % Rows ? Rows : LV_GetCount("Colum")
		LV_ModifyCol(A_Index, "Center")
}

LV_SetRowHeight(Height)
{
	LV_SetImageList( DllCall( "ImageList_Create", Int,2, Int, Height, Int,0x18, Int,1, Int,1 ), 1 )
}