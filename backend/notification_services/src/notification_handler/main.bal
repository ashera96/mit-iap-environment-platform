import ballerina/http;
import ballerina/io;
import ws_server;
import ballerina/log;

type Notification record {
    string receiver;
    string category;
    string description;
};

@http:ServiceConfig {
    basePath: "/"
}
service eventListener on new http:Listener(9090) {

    @http:ResourceConfig {
        path: "/event",
        methods: ["POST"]
    }
    resource function getEvent(http:Caller caller, http:Request request) {

        http:Response response = new;
        var data = request.getJsonPayload();
        if (data is json) {
            if (data.action is json) {
                var  event_action = data.action;
                if (event_action == "opened" ) {
                    // Issue created

                    // Notification for admin
                    Notification notification = {
                        receiver: "admin",
                        category: "Issue Created",
                        description: "New request was created"
                    };
                    response.statusCode = http:STATUS_OK;
                    response.setPayload("Success");
                    sendMessage(notification);
                } else if (event_action == "edited") {
                    // Issue Edited

                    // Notification for admin
                    Notification notification_admin = {
                        receiver: "admin",
                        category: "Issue Edited",
                        description: "Issue was edited"
                    };
                    response.statusCode = http:STATUS_OK;
                    response.setPayload("Success");
                    sendMessage(notification_admin);
                } else if (event_action == "closed") {
                    // Issue Closed

                    // Notification to the admin
                    Notification notification = {
                        receiver: "admin",
                        category: "Issue Closed",
                        description: "Request deleted"
                    };
                    response.statusCode = http:STATUS_OK;
                    response.setPayload("Success");
                    sendMessage(notification);

                    // Notification for user
                    string username = "";
                    map<json> | error issue = trap <map<json>>data.issue;
                    if (issue is map<json>) {
                        json[] | error labels = trap <json[]>issue.labels;
                        if (labels is json[]) {
                            string | error label_name = trap <string>labels[0].name;
                            if (label_name is string) {
                                username = label_name;
                            }
                        }
                    }
                    Notification notification_user = {
                        receiver: username,
                        category: "Issue Closed",
                        description: "Request deleted"
                    };
                    response.statusCode = http:STATUS_OK;
                    response.setPayload("Success");
                    sendMessage(notification_user);
                } else if (event_action == "created") {
                    // Comment Created

                    // Notification for admin
                    if (data.comment is json) {
                        var comment_body = data.comment.body;
                        Notification notification_admin = {
                            receiver: "admin",
                            category: "Comment Created",
                            description: "New comment was added."
                        };
                        response.statusCode = http:STATUS_OK;
                        response.setPayload("Success");
                        sendMessage(notification_admin);
                    }

                    // Notification for user
                    string username = "";
                    map<json> | error issue = trap <map<json>>data.issue;
                    if (issue is map<json>) {
                        json[] | error labels = trap <json[]>issue.labels;
                        if (labels is json[]) {
                            string | error label_name = trap <string>labels[0].name;
                            if (label_name is string) {
                                username = label_name;
                            }
                        }
                    }
                    Notification notification_user = {
                        receiver: username,
                        category: "Comment Created",
                        description: "New comment was added"
                    };
                    response.statusCode = http:STATUS_OK;
                    response.setPayload("Success");
                    sendMessage(notification_user);
                } else if (event_action == "labeled") {
                    // Issue was labeled

                    // Notification for admin
                    Notification notification = {
                        receiver: "admin",
                        category: "Label Added",
                        description: "New label was added"
                    };
                    response.statusCode = http:STATUS_OK;
                    response.setPayload("Success");
                    sendMessage(notification);
                }
            } else {
                log:printInfo("Error occured while retrieving the action from the payload");
                response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
                response.setPayload("Error occured while retrieving the action from the payload");
            }
        } else {
            log:printInfo("Invalid payload type recieved");
            response.statusCode =  http:STATUS_NOT_ACCEPTABLE;
            response.setPayload(<@untainted>data.reason());
        }
        error?respond = caller->respond(response);
    }
}

function sendMessage(Notification notification) {
    io:println(notification);

    json|error notificationJson = json.constructFrom(notification);
    if (notificationJson is json) {
        ws_server:WsUser[] ws = ws_server:getWebSocketClients();
        foreach ws_server:WsUser item in ws {
            if(item.user=== notification.receiver){
                http:WebSocketCaller wc= item.wsCaller;
                var a= wc->pushText(notificationJson.toJsonString());
            }
        }
    }
}
