codeunit 50101 "DocuSign Status Check"
{
    trigger OnRun();
    begin
        CheckStatus();
    end;

    local procedure CheckStatus()
    var
        DocusignLog: Record "Docusign Log";
        DocuSignManagement: Codeunit "DocuSign Management";
        Status: Text;
    begin
        DocusignLog.SetFilter(Status, '<>%1', DocusignLog.Status::Completed);
        if DocusignLog.FindSet() then
            repeat
                Status := DocuSignManagement.GetEnvelopeStatus(DocusignLog."Envelope ID");
                Evaluate(DocusignLog.Status, Status);
                DocusignLog.Modify();
            until DocusignLog.Next() = 0;
    end;
}
