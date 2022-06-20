import pubudu/policy_validator;
import pubudu/addHeader;
import ballerina/http;

listener http:Listener ep0 = new (8243, config = {host: "localhost"});

service /pizzashack/'1\.0\.0 on ep0 {
    resource function get menu(http:Caller caller, http:Request incomingRequest) returns error? {
policy_validator:MediationContext mediationCtx = {httpMethod: "get",resourcePath: string `/menu`};
		do {
			{
    var x = check addHeader:addHeader_In(incomingRequest, mediationCtx);

    if x is false {
        http:Response res1 = createAcceptedResponse();
        http:ListenerError? response = caller->respond(res1);
        return;
    } else if x is http:Response {
        http:ListenerError? response = caller->respond(x);
        return;
    }
}


			http:Response backendResponse = check backendEP->execute(mediationCtx.httpMethod, mediationCtx.resourcePath, incomingRequest);
			
{
    var x = check addHeader:addHeader_Out(backendResponse, incomingRequest, mediationCtx);

    if x is false {
        // handle stopping mediation midway
        return;
    } else if x is http:Response {
        http:ListenerError? response = caller->respond(x);
        return;
    }
}


{
    var x = check addHeader:addHeader_Out(backendResponse, incomingRequest, mediationCtx);

    if x is false {
        // handle stopping mediation midway
        return;
    } else if x is http:Response {
        http:ListenerError? response = caller->respond(x);
        return;
    }
}


			check caller->respond(backendResponse);
		} on fail var e {
			http:Response errFlowResponse = createDefaultErrorResponse(e);
			check caller->respond(errFlowResponse);
		}
    }
}

final http:Client backendEP = check new("http://localhost:9090");

function createDefaultErrorResponse(error e) returns http:Response {
    return new;
}

function createAcceptedResponse() returns http:Response {
    return new;
}

function copyRequestHeaders(http:Request req) returns map<string|string[]> {
    map<string|string[]> headers = {};
    string[] headerNames = req.getHeaderNames();
    foreach string name in headerNames {
        string[]|http:HeaderNotFoundError headersResult = req.getHeaders(name);

        if headersResult is string[] {
            if headersResult.length() == 1 {
              headers[name] = headersResult[0];
            } else {
              headers[name] = headersResult;
            }
        }
    }
    return headers;
}
