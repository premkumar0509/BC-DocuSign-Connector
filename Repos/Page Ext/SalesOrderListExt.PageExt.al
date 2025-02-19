pageextension 50101 SalesOrderListExt extends "Sales Order List"
{
    actions
    {
        addlast(processing)
        {
            action(SendToDocuSign)
            {
                Caption = 'Send to DocuSign';
                ApplicationArea = All;
                Image = SendAsPDF;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Executes the Send to DocuSign action.';

                trigger OnAction()
                var
                    DocuSignMgt: Codeunit "DocuSign Management";
                begin
                    if DocuSignMgt.SendDocument(Rec."Document Type", Rec."No.") then
                        Message('Order sent to DocuSign for signature.');
                end;
            }
        }
    }
}
