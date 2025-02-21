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

        APIEndpoint := 'https://demo.docusign.net/restapi/v2.1/accounts/' + DocuSignSetup."Account ID" + '/envelopes';

        // Create JSON payload for DocuSign API
        JSONPayload := GenerateRequestBody(Base64Text);

        // Make HTTP POST request
        HttpContent.WriteFrom(JSONPayload);
        HttpContent.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add('Content-Type', 'application/json');
        HttpClient.DefaultRequestHeaders().Add('Authorization', 'Bearer ' + DocuSignSetup."Access Token");

        if HttpClient.Post(APIEndpoint, HttpContent, HttpResponse) then
            if HttpResponse.HttpStatusCode = 201 then
                Message('Document sent successfully!')
            else
                Error('Failed to send document. Response: %1', HttpResponse.HttpStatusCode);
    end;

    procedure GenerateRequestBody(DocumentBase64: Text): Text;
    var
        JsonObject: JsonObject;
        JsonArray: JsonArray;
        Base64Convert: Codeunit "Base64 Convert";
        FileManagement: Codeunit "File Management";
    begin
        // Create the JSON object
        JsonObject.Add('documents', CreateDocumentsArray(DocumentBase64));
        JsonObject.Add('emailSubject', 'Test from Postman');
        JsonObject.Add('recipients', CreateRecipientsObject());
        JsonObject.Add('status', 'sent');

        exit(Format(JsonObject));
    end;

    procedure CreateDocumentsArray(DocumentBase64: Text): JsonArray
    var
        DocumentObject: JsonObject;
        DocumentArray: JsonArray;
    begin
        DocumentObject.Add('documentBase64', DocumentBase64);
        DocumentObject.Add('documentId', '1');
        DocumentObject.Add('fileExtension', 'pdf');
        DocumentObject.Add('name', 'Order-Confirmation');

        DocumentArray.Add(DocumentObject);
        exit(DocumentArray);
    end;

    procedure CreateRecipientsObject(): JsonObject
    var
        RecipientsObject: JsonObject;
        SignerArray: JsonArray;
        SignerObject: JsonObject;
    begin
        SignerObject.Add('email', 'premkumar.r.0509@gmail.com');
        SignerObject.Add('name', 'Premkumar');
        SignerObject.Add('recipientId', '1001');

        SignerArray.Add(SignerObject);
        RecipientsObject.Add('signers', SignerArray);
        exit(RecipientsObject);
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

    local procedure GetAccessToken()
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

    local procedure RefreshAccessToken()
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
        ExpiryTimeInteger: Integer;
        ExpiryTime: Time;
    begin
        if not DocuSignSetup.Get() then
            Error('DocuSign Setup not configured.');

        RequestBody := 'grant_type=refresh_token' +
                       '&refresh_token=' + DocuSignSetup."Refresh Token";

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
                    ExpiryTimeInteger := JsonToken.AsValue().AsInteger();

                // Store tokens in the table
                DocuSignSetup."Access Token" := CopyStr(AccessToken, 1, MaxStrLen(DocuSignSetup."Access Token"));
                DocuSignSetup."Refresh Token" := CopyStr(RefreshToken, 1, MaxStrLen(DocuSignSetup."Refresh Token"));
                ExpiryTime := DT2Time(CurrentDateTime) + (ExpiryTimeInteger * 1000);
                DocuSignSetup."Token Expiry" := CreateDateTime(Today, ExpiryTime);
                DocuSignSetup.Modify();
            end else
                // Improved error handling
                Error('Failed to get access token. Status Code: %1, Response: %2', HttpResponse.HttpStatusCode, ResponseText);
        end;
    end;
}