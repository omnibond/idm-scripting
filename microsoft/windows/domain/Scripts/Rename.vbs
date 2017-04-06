' Copyright (C) 2008 Novell, Inc.

Sub RENAME
  Dim Domain

  ' *** NOTE ***
  ' You can only rename users in a Domain, not Local users.

  Assoc = IDMGetEventValue("ASSOCIATION")
  NewName = IDMGetEventValue("NEW_NAME")
  IDMTrace "NEW_NAME=" & NewName
  If Assoc <> "" And NewName <> "" Then
    Tokens = Split(Assoc, "/")
    DomainName = Tokens(0)
    Set Domain = GetObject("WinNT://" & DomainName)
    Domain.MoveHere "WinNT://" & Assoc, NewName

    ' Change the association
    IDMSetCommand "REMOVE_ASSOCIATION"
    IDMWriteValue "ASSOCIATION", Assoc
    IDMSetCommand "ADD_ASSOCIATION"
    IDMWriteValue "ASSOCIATION", DomainName & "/" & NewName
    IDMWriteValue "DEST_DN", NewName
    IDMStatusSuccess "Rename event succeeded"
  Else
    IDMStatusError "Could not retrieve association and/or new name"
  End If
    
End Sub    
  