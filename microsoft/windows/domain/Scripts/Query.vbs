' Copyright (C) 2008 Novell, Inc.

Sub QUERY      
  Dim Identity
  Code = 0
  ' Check for association
  Assoc = IDMGetEventValue("ASSOCIATION")
  If Assoc <> "" Then
    On Error Resume Next
     Set Identity = GetObject("WinNT://" & Assoc)
    On Error GoTo 0
    If Not IsEmpty(Identity) Then
      ' Read associated object attributes
      IDMSetCommand "INSTANCE"
      IDMWriteValue "ASSOCIATION", Assoc
      IDMWriteValue "CLASS_NAME", IDMGetEventValue("CLASS_NAME")

      Attrs = IDMGetEventValues("READ_ATTRS")
      If Not IsEmpty(Attrs) Then
        For Each Attr In Attrs
          IDMTrace "IDMQuery: " & Attr
          If Attr = "CN" Then
            Value = Identity.Name
          Else
            On Error Resume Next
             Value = Identity.Get(Attr)
            On Error GoTo 0
          End If
          If Not IsEmpty(Value) Then
            If Attr = "AccountExpirationDate" Or Attr = "PasswordExpirationDate" Then
              DValue = DateDiff("s", "01/01/1970", Value)
              IDMWriteValue "ATTR_" & Attr, DValue
            Else
              IDMWriteValue "ATTR_" & Attr, Value
            End If
          End If
        Next
      End If
      ' return success
      IDMStatusSuccess "Query event succeeded"
    Else
      ' return error message
      IDMStatusError Err.Description
    End If
  Else 
    CN = IDMGetEventValue("SEARCH_ATTR_CN")
    DomainName = IDMGetEventValue("SEARCH_ATTR_DomainName")
    On Error Resume Next
     Set Identity = GetObject("WinNT://" & DomainName & "/" & CN)
    On Error GoTo 0
    Code = Hex(Err.Number)

    If Not IsEmpty(Identity) Then
      IDMSetCommand "INSTANCE"
      IDMWriteValue "CLASS_NAME", "User"
      IDMWriteValue "SRC_DN", CN
      IDMWriteValue "ASSOCIATION", DomainName & "/" & CN

      Set Identity = Nothing
    End If

    IDMStatusSuccess "Query event succeeded (code " & Code & ")"
  End If

End Sub    

