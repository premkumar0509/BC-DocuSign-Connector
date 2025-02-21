page 50101 "Docusign Log"
{
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Docusign Log';
    PageType = List;
    Editable = false;
    SourceTable = "Docusign Log";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ToolTip = 'Specifies the value of the Entry No. field.';
                }
                field("Document ID"; Rec."Document ID")
                {
                    ToolTip = 'Specifies the value of the Document ID field.';
                }
                field("Source Document Type"; Rec."Source Document Type")
                {
                    ToolTip = 'Specifies the value of the Source Document Type field.';
                }
                field("Source Document No."; Rec."Source Document No.")
                {
                    ToolTip = 'Specifies the value of the Source Document No. field.';
                }
                field(Recipients; Rec.Recipients)
                {
                    ToolTip = 'Specifies the value of the Recipients field.';
                }
                field("Recipients Name"; Rec."Recipients Name")
                {
                    ToolTip = 'Specifies the value of the Recipients field.';
                }
                field(Subject; Rec.Subject)
                {
                    ToolTip = 'Specifies the value of the Subject field.';
                }
                field("File Name"; Rec."File Name")
                {
                    ToolTip = 'Specifies the value of the Document Name field.';
                }
                field(Status; Rec.Status)
                {
                    ToolTip = 'Specifies the value of the Status field.';
                    StyleExpr = StatusStyle;
                }
                field("Request Body"; Rec.GetRequestBody())
                {
                    ToolTip = 'Specifies the value of the Request Body field.';
                }
                field("Response Body"; Rec.GetResponseBody())
                {
                    ToolTip = 'Specifies the value of the Response Body field.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        case Rec.Status of
            Rec.Status::Sent:
                StatusStyle := Format(PageStyle::Favorable);
            Rec.Status::Error:
                StatusStyle := Format(PageStyle::Unfavorable);
            else
                Clear(StatusStyle);
        end;
    end;

    var
        StatusStyle: Text;
}