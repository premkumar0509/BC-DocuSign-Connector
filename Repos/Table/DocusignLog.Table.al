table 50101 "Docusign Log"
{
    Caption = 'Docusign Log';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Document ID"; Integer)
        {
            Caption = 'Document ID';
        }
        field(3; "Source Document Type"; Enum "Sales Document Type")
        {
            Caption = 'Source Document Type';
        }
        field(4; "Source Document No."; Code[20])
        {
            Caption = 'Source Document No.';
        }
        field(5; Recipients; Text[200])
        {
            Caption = 'Recipients';
        }
        field(6; "Recipients Name"; Text[200])
        {
            Caption = 'Recipients';
        }
        field(7; Subject; Text[250])
        {
            Caption = 'Subject';
        }
        field(8; "File Name"; Code[200])
        {
            Caption = 'File Name';
        }
        field(9; Status; enum "DocuSign Envelope Status")
        {
            Caption = 'Status';
        }
        field(10; "Request Body"; Blob)
        {
            Caption = 'Request Body';
        }
        field(11; "Response Body"; Blob)
        {
            Caption = 'Response Body';
        }
        field(12; "Envelope ID"; Text[50])
        {
            Caption = 'Envelope ID';
        }
    }
    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }

    procedure SetRequestBody(RequestBody: Text)
    var
        OutStream: OutStream;
    begin
        Clear(Rec."Request Body");
        Rec."Request Body".CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(RequestBody);
        Rec.Modify();
    end;

    procedure GetRequestBody() RequestBody: Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        Rec.CalcFields("Request Body");
        Rec."Request Body".CreateInStream(InStream, TEXTENCODING::UTF8);
        exit(TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(InStream, TypeHelper.LFSeparator(), Rec.FieldName("Request Body")));
    end;


    procedure SetResponseBody(ResponseBody: Text)
    var
        OutStream: OutStream;
    begin
        Clear(Rec."Response Body");
        Rec."Response Body".CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(ResponseBody);
        Rec.Modify();
    end;

    procedure GetResponseBody() ResponseBody: Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        Rec.CalcFields("Response Body");
        Rec."Response Body".CreateInStream(InStream, TEXTENCODING::UTF8);
        exit(TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(InStream, TypeHelper.LFSeparator(), Rec.FieldName("Response Body")));
    end;

}