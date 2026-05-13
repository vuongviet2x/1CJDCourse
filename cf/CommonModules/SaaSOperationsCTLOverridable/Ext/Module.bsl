// @strict-types

#Region Public

// Sets default user rights.
// Run in SaaS when updating user rights in Service Manager without administrator rights.
// @skip-check module-empty-method - Overridable method.
// 
//
// Parameters:
//  User - CatalogRef.Users - user, 
//                 for which default rights are to be set.
//  AccessAllowed - Boolean - indicates whether access is granted. 
//                   If True, access is granted, if False, access is denied.
//
Procedure SetDefaultRights(User, AccessAllowed = True) Export
EndProcedure

// Sets access to data area API for a user.
// Run in SaaS when updating user rights in Service 
// Manager without administrator rights.
// @skip-check module-empty-method - Overridable method.
//
// Parameters:
//  User - CatalogRef.Users - user, to which API access rights are to be set.
//  AccessAllowed - Boolean - indicates whether access is granted.  
//                   If True, access is granted, if False, access is denied.
//
Procedure SetAccessToThisDataArea(User, AccessAllowed = True) Export
EndProcedure

#EndRegion
