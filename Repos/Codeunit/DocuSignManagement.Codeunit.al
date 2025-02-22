codeunit 50100 "DocuSign Management"
{
    procedure SendDocument(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]): Boolean
    var
        SalesHeader: Record "Sales Header";
        DocusignLog: Record "Docusign Log";
    begin
        SalesHeader.Get(DocumentType, DocumentNo);
        DocusignLog.Init();
        DocusignLog."Document ID" := GetLastDocumentID() + 1;
        DocusignLog."Source Document Type" := DocumentType;
        DocusignLog."Source Document No." := SalesHeader."No.";
        DocusignLog.Subject := 'Order Confirmation - ' + SalesHeader."No.";
        DocusignLog.Recipients := SalesHeader."Sell-to E-Mail";
        DocusignLog."Recipients Name" := SalesHeader."Bill-to Name";
        DocusignLog."File Name" := Format(SalesHeader."Document Type") + ' - ' + SalesHeader."No." + '.pdf';
        DocusignLog.Insert(true);

        if TrySendDocument(DocusignLog) then
            DocusignLog.Status := DocusignLog.Status::Sent
        else
            DocusignLog.Status := DocusignLog.Status::Error;

        DocusignLog.Modify();

        exit(DocusignLog.Status = DocusignLog.Status::Sent);
    end;

    local procedure GetLastDocumentID(): Integer
    var
        DocusignLog: Record "Docusign Log";
    begin
        if DocusignLog.FindLast() then
            exit(DocusignLog."Document ID");
    end;

    [TryFunction]
    local procedure TrySendDocument(var DocusignLog: Record "Docusign Log")
    var
        DocuSignSetup: Record "DocuSign Setup";
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        Headers: HttpHeaders;
        HttpResponse: HttpResponseMessage;
        TokenType: Option AccessToken,RefreshToken;
        APIEndpoint, Base64Text, RequestBody, ResponseBody : Text;
        JsonResponse: JsonObject;
        JsonToken: JsonToken;
        AcessToken: Text;
    begin
        // Retrieve API credentials
        if not DocuSignSetup.Get() then
            Error('DocuSign Setup not configured.');

        if DocuSignSetup."Token Expiry" = 0DT then
            AcessToken := GetToken(TokenType::AccessToken)
        else
            if DocuSignSetup."Token Expiry" < CurrentDateTime then
                AcessToken := GetToken(TokenType::RefreshToken)
            else
                AcessToken := DocuSignSetup."Access Token";

        Base64Text := GetReportBase64Text(DocusignLog."Source Document Type", DocusignLog."Source Document No.");

        // Create JSON payload for DocuSign API
        RequestBody := GenerateRequestBody(DocusignLog."Document ID", DocusignLog."File Name", Base64Text,
                                           DocusignLog.Recipients, DocusignLog."Recipients Name", DocusignLog.Subject);

        APIEndpoint := 'https://demo.docusign.net/restapi/v2.1/accounts/' + DocuSignSetup."Account ID" + '/envelopes';
        // Make HTTP POST request
        HttpContent.WriteFrom(RequestBody);
        HttpContent.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add('Content-Type', 'application/json');
        HttpClient.DefaultRequestHeaders().Add('Authorization', 'Bearer ' + AcessToken);
        DocusignLog.SetRequestBody(RequestBody);

        if HttpClient.Post(APIEndpoint, HttpContent, HttpResponse) then begin
            HttpResponse.Content.ReadAs(ResponseBody);
            DocusignLog.SetResponseBody(ResponseBody);
            if HttpResponse.HttpStatusCode = 201 then begin
                JsonResponse.ReadFrom(ResponseBody);
                // Extract Envelope ID
                if JsonResponse.Get('envelopeId', JsonToken) then
                    DocusignLog."Envelope ID" := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(DocusignLog."Envelope ID"));

            end else
                Error('Failed to send document. Response Code: %1, Response: %2', HttpResponse.HttpStatusCode, ResponseBody);
        end;
    end;

    local procedure GetReportBase64Text(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]): Text;
    var
        SalesHeader: Record "Sales Header";
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        FldRef: FieldRef;
        InStr: InStream;
        OutStr: OutStream;
    begin
        SalesHeader.Get(DocumentType, DocumentNo);
        RecRef.GetTable(SalesHeader);
        FldRef := RecRef.Field(SalesHeader.FieldNo("No."));
        FldRef.SetRange(SalesHeader."No.");
        TempBlob.CreateOutStream(OutStr);
        Report.SaveAs(Report::"Standard Sales - Order Conf.", '', ReportFormat::Pdf, OutStr, RecRef);
        TempBlob.CreateInStream(InStr);
        exit(Base64Convert.ToBase64(InStr, false));
    end;

    local procedure GenerateRequestBody(DocumentID: Integer; DocumentName: Text; DocumentBase64: Text; Receipt: Text; ReceiptName: Text; Subject: Text): Text;
    var
        JsonObject, DocumentObject, SignerObject, RecipientsObject : JsonObject;
        DocumentArray, SignerArray : JsonArray;
    begin
        DocumentObject.Add('documentBase64', DocumentBase64);
        DocumentObject.Add('documentId', DocumentID);
        DocumentObject.Add('fileExtension', 'pdf');
        DocumentObject.Add('name', DocumentName);
        DocumentArray.Add(DocumentObject);

        // Create the Signer object
        SignerObject.Add('email', Receipt);
        SignerObject.Add('name', ReceiptName);
        SignerObject.Add('recipientId', '1001');
        SignerArray.Add(SignerObject);
        RecipientsObject.Add('signers', SignerArray);

        // Create the JSON object
        JsonObject.Add('documents', DocumentArray);
        JsonObject.Add('emailSubject', Subject);
        JsonObject.Add('recipients', RecipientsObject);
        JsonObject.Add('status', 'sent');

        exit(Format(JsonObject));
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

    local procedure GetToken(TokenType: Option AccessToken,RefreshToken) AccessToken: Text;
    var
        DocuSignSetup: Record "DocuSign Setup";
        Base64Convert: Codeunit "Base64 Convert";
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        HttpResponse: HttpResponseMessage;
        Headers: HttpHeaders;
        RequestBody: Text;
        ResponseBody: Text;
        JsonResponse: JsonObject;
        JsonToken: JsonToken;
        RefreshToken: Text;
        ExpiryTime: Integer;
        Time: Time;
    begin
        DocuSignSetup.Get();

        if TokenType = TokenType::AccessToken then
            RequestBody := 'grant_type=authorization_code' + '&code=' + DocuSignSetup."Auth Code"
        else
            if TokenType = TokenType::RefreshToken then
                RequestBody := 'grant_type=refresh_token' + '&refresh_token=' + DocuSignSetup."Refresh Token";

        HttpContent.WriteFrom(RequestBody);
        HttpContent.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add('Content-Type', 'application/x-www-form-urlencoded');
        HttpClient.DefaultRequestHeaders().Add('Authorization', 'Basic ' + Base64Convert.ToBase64(DocuSignSetup."Client ID" + ':' + DocuSignSetup."Client Secret", false));

        if HttpClient.Post('https://account-d.docusign.com/oauth/token', HttpContent, HttpResponse) then begin
            HttpResponse.Content.ReadAs(ResponseBody);

            if HttpResponse.IsSuccessStatusCode then begin
                JsonResponse.ReadFrom(ResponseBody);

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
                Commit();
            end else begin
                // Improved error handling
                JsonResponse.ReadFrom(ResponseBody);
                if JsonResponse.Get('error_description', JsonToken) then begin
                    if ('expired_client_token' = JsonToken.AsValue().AsText()) then begin

                        if Confirm('Auth Code is expired! Do you want to generate new ?') then
                            GetAuthorizationCode()
                        else
                            Error('');
                    end else
                        Error('Failed to get access token. Status Code: %1, Response: %2', HttpResponse.HttpStatusCode, ResponseBody);
                end
                else
                    Error('Failed to get access token. Status Code: %1, Response: %2', HttpResponse.HttpStatusCode, ResponseBody);
            end;
        end;
    end;

    procedure GetEnvelopeStatus(EnvelopeId: Text): Text
    var
        DocuSignSetup: Record "DocuSign Setup";
        TokenType: Option AccessToken,RefreshToken;
        Client: HttpClient;
        RequestHeaders: HttpHeaders;
        RequestMessage: HttpRequestMessage;
        Response: HttpResponseMessage;
        AcessToken, ReponseBody : Text;
        JsonObject: JsonObject;
        JsonToken: JsonToken;
    begin
        DocuSignSetup.Get();

        if DocuSignSetup."Token Expiry" = 0DT then
            AcessToken := GetToken(TokenType::AccessToken)
        else
            if DocuSignSetup."Token Expiry" < CurrentDateTime then
                AcessToken := GetToken(TokenType::RefreshToken)
            else
                AcessToken := DocuSignSetup."Access Token";

        RequestMessage.SetRequestUri('https://demo.docusign.net/restapi/v2.1/accounts/' + DocuSignSetup."Account ID" + '/envelopes/' + EnvelopeId);
        RequestMessage.Method('GET');
        RequestMessage.GetHeaders(RequestHeaders);
        RequestHeaders.Add('Authorization', 'Bearer ' + AcessToken);

        if Client.Send(RequestMessage, Response) then begin
            if Response.IsSuccessStatusCode then begin
                Response.Content.ReadAs(ReponseBody);
                JsonObject.ReadFrom(ReponseBody);
                if JsonObject.Get('status', JsonToken) then
                    exit(JsonToken.AsValue().AsText());
            end else
                Error('Failed to get status. Status Code: %1, Response: %2', Response.HttpStatusCode, ReponseBody);
        end else
            Error('HTTP request to DocuSign failed. - %1', GetLastErrorText());
    end;

    procedure DownloadSignedDocument(EnvelopeId: Text; DocumentID: Integer; FileName: Text)
    var
        DocuSignSetup: Record "DocuSign Setup";
        TokenType: Option AccessToken,RefreshToken;
        Client: HttpClient;
        RequestHeaders: HttpHeaders;
        RequestMessage: HttpRequestMessage;
        Response: HttpResponseMessage;
        AcessToken, ReponseBody : Text;
        FileContent: InStream;
    begin
        DocuSignSetup.Get();

        if DocuSignSetup."Token Expiry" = 0DT then
            AcessToken := GetToken(TokenType::AccessToken)
        else
            if DocuSignSetup."Token Expiry" < CurrentDateTime then
                AcessToken := GetToken(TokenType::RefreshToken)
            else
                AcessToken := DocuSignSetup."Access Token";

        RequestMessage.SetRequestUri('https://demo.docusign.net/restapi/v2.1/accounts/' + DocuSignSetup."Account ID" + '/envelopes/' + EnvelopeId + '/documents/' + Format(DocumentID));
        RequestMessage.Method('GET');
        RequestMessage.GetHeaders(RequestHeaders);
        RequestHeaders.Add('Authorization', 'Bearer ' + AcessToken);

        if Client.Send(RequestMessage, Response) then begin
            if Response.IsSuccessStatusCode then begin
                Response.Content.ReadAs(FileContent);
                DownloadFromStream(FileContent, '', '', '', FileName);
            end else begin
                Response.Content.ReadAs(ReponseBody);
                Error('Failed to get document. Status Code: %1, Response: %2', Response.HttpStatusCode, ReponseBody);
            end;
        end else
            Error('HTTP request to DocuSign failed. - %1', GetLastErrorText());
    end;
}