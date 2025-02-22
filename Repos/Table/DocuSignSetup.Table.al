table 50100 "DocuSign Setup"
{
    Caption = 'DocuSign Setup';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Client ID"; Text[100])
        {
            Caption = 'Client ID';
        }
        field(3; "Client Secret"; Text[100])
        {
            Caption = 'Client Secret';
        }
        field(4; "User ID"; Text[50])
        {
            Caption = 'User ID';
        }
        field(5; "API Base URL"; Text[100])
        {
            Caption = 'API Base URL';
        }
        field(6; "Redirect URI"; Text[200])
        {
            Caption = 'Redirect URI';
        }
        field(7; "Access Token"; Text[2048])
        {
            Caption = 'Access Token';
        }
        field(8; "Refresh Token"; Text[2048])
        {
            Caption = 'Refresh Token';
        }
        field(9; "Token Expiry"; DateTime)
        {
            Caption = 'Token Expiry';
        }
        field(10; "Auth Code"; Text[2048])
        {
            Caption = 'Auth Code';
        }
        field(11; "Account ID"; Text[50])
        {
            Caption = 'Account ID';
        }
    }



    keys
    { key(PK; "Primary Key") { Clustered = true; } }
}
