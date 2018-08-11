b64_encode(p*) {
	return b64.encode(p*)
}

b64_decode(p*) {
	return b64.decode(p*)
}

class b64
{
	encode(ByRef sText, bIsUtf16 := false)
	{
		ele := ComObjCreate("Msxml2.DOMDocument").CreateElement("aux")
		ele.DataType := "bin.base64"
		ele.NodeTypedValue := bIsUtf16 ? this.strToBytes(sText, "utf-16le", 2)
		                               : this.strToBytes(sText, "utf-8", 3)
		return ele.Text
	}

	encode_fromfile(filename, ByRef result)
	{
		ele := ComObjCreate("Msxml2.DOMDocument").CreateElement("aux")
		ele.DataType := "bin.base64"
		ele.NodeTypedValue := this.fileToBytes(filename)
		result := StrReplace(ele.Text, "`n")
	}

	fileToBytes(FileName)
	{
		oADO := ComObjCreate("ADODB.Stream")

		oADO.Type := 1 ; adTypeBinary
		oADO.Open
		oADO.LoadFromFile(FileName)
		return oADO.Read, oADO.Close
	}

	decode(ByRef sBase64EncodedText, bIsUtf16 := false)
	{
		ele := ComObjCreate("Msxml2.DOMDocument").CreateElement("aux")
		ele.DataType := "bin.base64"
		ele.Text := sBase64EncodedText
		return this.bytesToStr(ele.NodeTypedValue, bIsUtf16 ? "utf-16le" : "utf-8")
	}

	strToBytes(ByRef sText, sEncoding, iBomByteCount)
	{
		oADO := ComObjCreate("ADODB.Stream")

		oADO.Type := 2 ; adTypeText
		oADO.Mode := 3 ; adModeReadWrite
		oADO.Open
		oADO.Charset := sEncoding
		oADO.WriteText(sText)

		oADO.Position := 0
		oADO.Type := 1 ; adTypeBinary
		oADO.Position := iBomByteCount ; skip the BOM
		return oADO.Read, oADO.Close
	}

	bytesToStr(byteArray, sTextEncoding)
	{
		oADO := ComObjCreate("ADODB.Stream")

		oADO.Type := 1 ; adTypeBinary
		oADO.Mode := 3 ; adModeReadWrite
		oADO.Open
		oADO.Write(byteArray)

		oADO.Position := 0
		oADO.Type := 2 ; adTypeText
		oADO.Charset  := sTextEncoding
		return oADO.ReadText, oADO.Close
	}
}