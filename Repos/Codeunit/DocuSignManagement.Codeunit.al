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

        if DocuSignSetup."Token Expiry" = 0DT then
            GetAccessToken()
        else
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


    procedure GetAccessToken()
    var
        DocuSignSetup: Record "DocuSign Setup";
        Base64Convert: Codeunit "Base64 Convert";
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
        ExpiryTime: Integer;
        Time: Time;
    begin
        DocuSignSetup.Get();

        RequestBody := 'grant_type=authorization_code' +
                       '&code=' + DocuSignSetup."Authorization Code";

        HttpContent.WriteFrom(RequestBody);
        HttpContent.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add('Content-Type', 'application/x-www-form-urlencoded');
        HttpClient.DefaultRequestHeaders().Add('Authorization', 'Basic ' + Base64Convert.ToBase64(DocuSignSetup."Client ID" + ':' + DocuSignSetup."Client Secret", false));

        if HttpClient.Post('https://account-d.docusign.com/oauth/token', HttpContent, HttpResponse) then begin
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
                    ExpiryTime := JsonToken.AsValue().AsInteger();

                // Store tokens in the table
                DocuSignSetup."Access Token" := CopyStr(AccessToken, 1, MaxStrLen(DocuSignSetup."Access Token"));
                DocuSignSetup."Refresh Token" := CopyStr(RefreshToken, 1, MaxStrLen(DocuSignSetup."Refresh Token"));
                Time := DT2Time(CurrentDateTime) + (ExpiryTime * 1000);
                DocuSignSetup."Token Expiry" := CreateDateTime(Today, Time);
                DocuSignSetup.Modify();
            end else begin
                // Improved error handling
                JsonResponse.ReadFrom(ResponseText);
                if JsonResponse.Get('error_description', JsonToken) then begin
                    if ('expired_client_token' = JsonToken.AsValue().AsText()) and Confirm('Auth Code is expired! Do you want to generate new ?') then
                        GetAuthorizationCode()
                    else
                        Error('');
                end
                else
                    Error('Failed to get access token. Status Code: %1, Response: %2', HttpResponse.HttpStatusCode, ResponseText);
            end;
        end;
    end;

    procedure GetAuthorizationCode(): Text
    var
        DocuSignSetup: Record "DocuSign Setup";
        AuthURL: Text;
    begin
        DocuSignSetup.Get();
        DocuSignSetup.TestField("Client ID");
        DocuSignSetup.TestField("Redirect URI");

        AuthURL := 'https://account-d.docusign.com/oauth/auth?' +
                   'response_type=code' +
                   '&scope=signature' +
                   '&client_id=' + DocuSignSetup."Client ID" +
                   '&redirect_uri=' + DocuSignSetup."Redirect URI";

        Hyperlink(AuthURL);

        exit(AuthURL);
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
                       '&code=' + DocuSignSetup."Authorization Code" +
                       '&client_id=' + DocuSignSetup."Client ID";

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
                DocuSignSetup."Access Token" := CopyStr(AccessToken, 1, MaxStrLen(DocuSignSetup."Access Token"));
                DocuSignSetup."Refresh Token" := CopyStr(RefreshToken, 1, MaxStrLen(DocuSignSetup."Refresh Token"));
                DocuSignSetup."Token Expiry" := CreateDateTime(Today, ExpiryTime);
                DocuSignSetup.Modify();
            end else
                // Improved error handling
                Error('Failed to get access token. Status Code: %1, Response: %2', HttpResponse.HttpStatusCode, ResponseText);
        end;
    end;
}