httpPost(URL, ByRef In_POST__Out_Data, Encoding := "") {
	static nothing := ComObjError(0)
	static oHTTP   := ComObjCreate("WinHttp.WinHttpRequest.5.1")

	oHTTP.Open("POST", URL, True)
	oHTTP.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")
	oHTTP.Send(In_POST__Out_Data)
	oHTTP.WaitForResponse(-1)

	if Encoding
	{
		static oADO   := ComObjCreate("adodb.stream")
		oADO.Type     := 1
		oADO.Mode     := 3
		oADO.Open()
		oADO.Write( oHTTP.ResponseBody )
		oADO.Position := 0
		oADO.Type     := 2
		oADO.Charset  := Encoding
		
		In_POST__Out_Data := oADO.ReadText()
		oADO.Close()
		return
	}

	In_POST__Out_Data := oHTTP.ResponseText
}