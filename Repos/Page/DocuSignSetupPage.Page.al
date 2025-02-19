page 50100 "DocuSign Setup Page"
{
    PageType = Card;
    SourceTable = "DocuSign Setup";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'DocuSign Setup';

    layout
    {
        area(content)
        {
            group(General)
            {
                field("Client ID"; Rec."Client ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Client ID field.';
                }
                field("Client Secret"; Rec."Client Secret")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Client Secret field.';
                }
                field("Account ID"; Rec."Account ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Account ID field.';
                }
                field("API Base URL"; Rec."API Base URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the API Base URL field.';
                }
                field("Authorization Code"; Rec."Access Token")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Access Token field.';
                }

                field("Redirect URI"; Rec."Redirect URI")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Redirect URI field.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Get Token")
            {
                ApplicationArea = All;
                Image = AllocatedCapacity;
                Caption = 'Get Access Token';
                ToolTip = 'Executes the Get Access Token action.';

                trigger OnAction()
                begin
                    GetAuthorizationURL();
                end;
            }
        }
        area(Promoted)
        {
            actionref(GetToken_Promoted; "Get Token")
            {
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;

    procedure GetAuthorizationURL(): Text
    var
        AuthURL: Text;
    begin
        Rec.TestField("Client ID");
        Rec.TestField("Redirect URI");

        AuthURL := 'https://account-d.docusign.com/oauth/auth?' +
                   'response_type=code' +
                   '&scope=signature' +
                   '&client_id=' + Rec."Client ID" +
                   '&redirect_uri=' + Rec."Redirect URI";

        Message('Click OK to open login page.');
        Hyperlink(AuthURL);

        exit(AuthURL);
    end;
}
