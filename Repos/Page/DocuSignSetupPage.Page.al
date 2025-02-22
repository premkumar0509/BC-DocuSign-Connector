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
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the User ID field.';
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
                field("Redirect URI"; Rec."Redirect URI")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Redirect URI field.';
                }
                field("Authorization Code"; Rec."Auth Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Authorization Token field.';
                }
                field("Token Expiry"; Rec."Token Expiry")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Token Expiry field.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Get Authorization Code")
            {
                ApplicationArea = All;
                Image = LaunchWeb;
                Caption = 'Get Authorization Code';
                ToolTip = 'Executes the Get Authorization Code action.';

                trigger OnAction()
                var
                    DocuSignManagement: Codeunit "DocuSign Management";
                begin
                    DocuSignManagement.GetAuthorizationCode();
                end;
            }
        }
        area(Promoted)
        {
            actionref(GetAuthorizationCode_Promoted; "Get Authorization Code")
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
}