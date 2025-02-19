codeunit 50100 "DocuSign Management"
{
    procedure SendDocument(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]): Boolean
    var
        DocuSignSetup: Record "DocuSign Setup";
        SalesHeader: Record "Sales Header";
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        FldRef: FieldRef;
        InStr: InStream;
        OutStr: OutStream;
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        Headers: HttpHeaders;
        HttpResponse: HttpResponseMessage;
        JSONPayload, APIEndpoint, Base64Text : Text;
    begin
        // Retrieve API credentials
        if not DocuSignSetup.Get() then
            Error('DocuSign Setup not configured.');

        if DocuSignSetup."Token Expiry" < CurrentDateTime then
            RefreshAccessToken();

        SalesHeader.Get(DocumentType, DocumentNo);

        RecRef.GetTable(SalesHeader);
        FldRef := RecRef.Field(SalesHeader.FieldNo("No."));
        FldRef.SetRange(SalesHeader."No.");
        TempBlob.CreateOutStream(OutStr);
        Report.SaveAs(Report::"Standard Sales - Order Conf.", '', ReportFormat::Pdf, OutStr, RecRef);
        TempBlob.CreateInStream(InStr);
        Base64Text := Base64Convert.ToBase64(InStr, false);

        APIEndpoint := DocuSignSetup."API Base URL" + '/v2.1/accounts/' + DocuSignSetup."Account ID" + '/envelopes';

        // Create JSON payload for DocuSign API
        JSONPayload := '{ "emailSubject": "Please sign this invoice",';
        JSONPayload += '   "documents": [ { "documentBase64": ' + Base64Text + ', ';
        JSONPayload += ' "name": "Invoice.pdf", "fileExtension": "pdf", "documentId": "1" } ], ';
        JSONPayload += '  "recipients": { "signers": [ { "email": "recipient@example.com", "name": "John Doe", "recipientId": "1", "routingOrder": "1" } ] }, ';
        JSONPayload += '   "status": "sent" }';

        // Make HTTP POST request
        HttpContent.WriteFrom(JSONPayload);
        HttpContent.GetHeaders(Headers); // Correct way to get headers
        Headers.Clear();
        Headers.Add('Content-Type', 'application/json');
        HttpClient.DefaultRequestHeaders().Add('Authorization', 'Bearer ' + DocuSignSetup."Access Token");

        if HttpClient.Post(APIEndpoint, HttpContent, HttpResponse) then
            if HttpResponse.HttpStatusCode = 201 then
                Message('Document sent successfully!')
            else
                Error('Failed to send document. Response: %1', HttpResponse.HttpStatusCode);
    end;

    procedure RefreshAccessToken()
    var
        DocuSignSetup: Record "DocuSign Setup";
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        HttpResponse: HttpResponseMessage;
        Headers: HttpHeaders;
        RequestBody: Text;
        ResponseText: Text;
        JsonResponse: JsonObject;
        JsonToken: JsonToken;
        AccessToken: Text;
        RefreshToken: Text;
        ExpiryTime: Time;
    begin
        if not DocuSignSetup.Get() then
            Error('DocuSign Setup not configured.');

        RequestBody := 'grant_type=authorization_code' +
                       '&code=' + DocuSignSetup."Access Token" +
                       '&client_id=' + DocuSignSetup."Client ID" +
                       '&client_secret=' + DocuSignSetup."Client Secret" +
                       '&redirect_uri=' + DocuSignSetup."Redirect URI";

        HttpContent.WriteFrom(RequestBody);
        HttpContent.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add('Content-Type', 'application/x-www-form-urlencoded');

        if HttpClient.Post('https://account.docusign.com/oauth/token', HttpContent, HttpResponse) then begin
            HttpResponse.Content.ReadAs(ResponseText);

            if HttpResponse.IsSuccessStatusCode then begin

                JsonResponse.ReadFrom(ResponseText);

                // Extract Access Token
                if JsonResponse.Get('access_token', JsonToken) then
                    AccessToken := JsonToken.AsValue().AsText();

                // Extract Refresh Token
                if JsonResponse.Get('refresh_token', JsonToken) then
                    RefreshToken := JsonToken.AsValue().AsText();

                // Extract Expiry Time
                if JsonResponse.Get('expires_in', JsonToken) then
                    ExpiryTime := JsonToken.AsValue().AsTime();

                // Store tokens in the table
                DocuSignSetup."Access Token" := AccessToken;
                DocuSignSetup."Refresh Token" := RefreshToken;
                DocuSignSetup."Token Expiry" := CreateDateTime(Today, ExpiryTime);
                DocuSignSetup.Modify();
            end
            else
                Error('Failed to get access token. %1', ResponseText);
        end else
            Error('Failed to get access token.');
    end;

}
