' Copyright (C) 2008 Novell, Inc.

' Handle attribute events
Sub DoAttributes(Identity)
  Names = IDMGetEventValueNames
  ' Process remove values first
  For Each Name In Names
    If Left(Name, 7) = "REMOVE_" And Not Left(Name, 11) = "REMOVE_REF_" Then
      If Left(Name, 11) = "REMOVE_ALL_" Then
        AttrName = Mid(Name, 12)
      Else
        AttrName = Mid(Name, 8)
      End If
      If AttrName = "AccountExpirationDate" Or AttrName = "PasswordExpirationDate" Then
        ' Set to never expire
        Identity.Put AttrName, #1/1/1970#
      ElseIf AttrName = "AccountDisabled" Or AttrName = "IsAccountLocked" Or AttrName = "PasswordRequired" Then
        Command = "Identity." & AttrName & " = False"
        Execute Command
      ElseIf AttrName = "MaxLogins" Or AttrName = "PasswordMinimumLength" Then
        ' Ignore error - not supported on local accounts
        On Error Resume Next
         Identity.Put AttrName, 0
        On Error GoTo 0
      ElseIf AttrName <> "CN" And AttrName <> "Member" And AttrName <> "DomainName" Then
        ' TODO: Ignore mismatched attr
        ' Clear attribute
        Command = "Identity." & AttrName & " = """""
        Execute Command
      End If
    End If
  Next
  For Each Name In Names
    ' Add/set attribute values
    If Left(Name, 4) = "ADD_" And Not Left(Name, 8) = "ADD_REF_" Then
      AttrName = Mid(Name, 5)
      If AttrName = "AccountExpirationDate" Or AttrName = "PasswordExpirationDate" Then
        Value = CLng(IDMGetEventValue(Name))
        VDate = DateAdd("s", Value, "1/1/1970 00:00")
        ' Adjust for Time Zone
        For Each OS In GetObject("WinMgmts:").InstancesOf("Win32_OperatingSystem")
          ' Only one OS is returned
          VDate = DateAdd("n", OS.CurrentTimeZone, VDate)
        Next
        Identity.Put AttrName, VDate
      ElseIf AttrName <> "CN" And AttrName <> "Member" And AttrName <> "DomainName" Then
        Value = IDMGetEventValue(Name)
        ' Use Execute to do automatic type conversion
        Command = "Identity." & AttrName & " = Value"
        Execute Command
      End If
    End If
  Next
  Identity.SetInfo
End Sub

Sub DoMembership(Group, DomainRoot)
  Names = IDMGetEventValueNames
  For Each Name In Names
    If Name = "REMOVE_ALL_Member" Then
      Set CurrentMembers = Group.Members
      For Each CurrentMember In CurrentMembers
        Group.Remove(DomainRoot & CurrentMember.Name)
      Next
      Exit For
    End If
  Next
  Members = IDMGetEventValues("REMOVE_REF_Member")
  If Not IsEmpty(Members) Then
    For Each Member In Members
      If Group.IsMember("WinNT://" & Member) Then
        Group.Remove("WinNT://" & Member)
      End If
    Next
  End If
  Group.SetInfo
  Members = IDMGetEventValues("ADD_REF_Member")
  If Not IsEmpty(Members) Then
    For Each Member In Members
      Group.Add("WinNT://" & Member)
    Next
  End If
End Sub

Sub MODIFY
  Dim Identity

  Assoc = IDMGetEventValue("ASSOCIATION")
  ClassName = IDMGetEventValue("CLASS_NAME")
  If Assoc <> "" And ClassName <> "" Then
    ' Assoc is in Domain/Name format
    DN = "WinNT://" & Assoc
    ' Get Domain name
    Tokens = Split(Assoc, "/")
    DomainRoot = "WinNT://" & Tokens(0) & "/"

    ' Load the object from the domain
    Set Identity = GetObject(DN)

    ' Set Attribute values
    DoAttributes Identity

    If ClassName = "Group" Then
      ' Handle group membership change
      DoMembership Identity, DomainRoot
    End If

    IDMStatusSuccess "Modify event succeeded"
  Else
    IDMStatusError "Could not retrieve association and/or class name"
  End If

End Sub    
  