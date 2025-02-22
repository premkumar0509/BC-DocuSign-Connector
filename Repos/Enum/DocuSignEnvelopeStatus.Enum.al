enum 50100 "DocuSign Envelope Status"
{
    Extensible = true;
    Caption = 'DocuSign Envelope Status';

    value(0; Sent)
    {
        Caption = 'Sent'; //Document sent but not yet opened
    }

    value(1; Delivered)
    {
        Caption = 'Delivered'; //Document opened but not yet signed
    }

    value(2; Completed)
    {
        Caption = 'Completed'; //Recipient signed the document
    }

    value(3; Declined)
    {
        Caption = 'Declined'; //Recipient refused to sign
    }

    value(4; Voided)
    {
        Caption = 'Voided'; //Envelope canceled by the sender
    }
    value(5; Error)
    {
        Caption = 'Error'; //Envelope canceled by the sender
    }
}
