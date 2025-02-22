permissionset 50100 "BC DocuSign Conn."
{
    Caption = 'BC DocuSign Connector';
    Assignable = true;
    Permissions = tabledata "DocuSign Setup" = RIMD,
        table "DocuSign Setup" = X,
        codeunit "DocuSign Management" = X,
        page "DocuSign Setup Page" = X,
        tabledata "Docusign Log" = RIMD,
        table "Docusign Log" = X,
        codeunit "DocuSign Status Check" = X,
        page "Docusign Log" = X;
}